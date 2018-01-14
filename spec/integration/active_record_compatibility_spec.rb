require "spec_helper"

describe "ActiveRecord compatibility", orm: :active_record do
  describe "#assign_attributes" do
    let!(:post) { Post.create(title: "foo title") }

    it "assigns translated attributes" do
      post.assign_attributes(title: "bar title")
      expect(post.title).to eq("bar title")
      Mobility.locale = :ja
      expect(post.title).to eq(nil)
      post.assign_attributes(title: "タイトル")
      expect(post.title).to eq("タイトル")
    end

    it "assigns untranslated attributes" do
      post.assign_attributes(published: false)
      expect(post.published).to eq(false)
      Mobility.locale = :ja
      expect(post.published).to eq(false)
      post.assign_attributes(published: true)
      expect(post.published).to eq(true)
      Mobility.locale = :en
      expect(post.published).to eq(true)
    end
  end

  describe "cache" do
    let!(:post) { Post.create(title: "foo title") }

    it "updates cache when translations association is modified directly" do
      expect(post.title).to eq("foo title")
      post.send(post.title_backend.association_name).first.value = "association changed value"
      expect(post.title).to eq("association changed value")
      post.title = "writer changed value"
      expect(post.title).to eq("writer changed value")
      post.send(post.title_backend.association_name).first.value = "association changed value"
      post.save
      expect(Post.first.title).to eq("association changed value")
    end

    it "resets cache when model is reloaded", rails_version_geq: '5.0' do
      expect(post.mobility_backend_for("title")).to receive(:clear_cache).once
      post.reload
    end
  end

  describe "dirty tracking" do
    let!(:post) { Post.create(title: "foo title") }

    it "tracks translated attributes" do
      expect(post.title).to eq("foo title")
      post.title = "bar"
      expect(post.changed?).to eq(true)
      expect(post.changed).to eq(["title_en"])
      expect(post.changes).to eq({ "title_en" => ["foo title", "bar"]})

      post.title = "baz"
      expect(post.changed?).to eq(true)
      expect(post.changed).to eq(["title_en"])
      expect(post.changes).to eq({ "title_en" => ["foo title", "baz"]})

      post.title = "foo title"
      expect(post.changed?).to eq(false)
      expect(post.changed).to eq([])
      expect(post.changes).to eq({})
    end

    it "resets original values when model is reloaded" do
      post.title = "foo"
      expect(post.changed?).to eq(true)
      post.reload
      expect(post.changed?).to eq(false)
    end
  end

  describe "fallbacks" do
    let!(:post) { FallbackPost.create(title: "foo title") }

    it "falls through to default locale with no options" do
      Mobility.locale = :ja
      expect(post.title).to eq("foo title")
    end

    it "does not fall through to default locale when fallback: false option passed in" do
      Mobility.locale = :ja
      expect(post.title(fallback: false)).to eq(nil)
    end

    it "does not fall through to default locale when locale is set explicitly" do
      Mobility.locale = :en
      expect(post.title(locale: :ja)).to eq(nil)
    end

    it "does not fall through to default locale when locale accessor is used" do
      Mobility.locale = :en
      expect(post.title_ja).to eq(nil)
    end
  end

  describe "#attributes" do
    it "includes both original and translated attributes" do
      post = Post.new
      post.title = "foo"
      post.content = "bar"
      expect(post.attributes).to include_hash({ "published" => post.published, "id" => post.id, "title" => "foo", "content" => "bar" })
    end
  end

  describe "#translated_attributes" do
    it "includes only translated attributes" do
      post = Post.new
      post.title = "foo"
      post.content = "bar"
      expect(post.translated_attributes).to eq({ "title" => "foo", "content" => "bar" }) end
  end

  describe "#untranslated_attributes" do
    it "includes only original attributes" do
      post = Post.new
      post.title = "foo"
      post.content = "bar"
      expect(post.untranslated_attributes).to include_hash({ "published" => post.published, "id" => post.id })
    end
  end

  describe "#translated_attribute_names" do
    it "delegates to class method" do
      post = Post.new
      expect(post.translated_attribute_names).to match_array(%w[title content])
    end
  end

end
