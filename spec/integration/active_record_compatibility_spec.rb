require "spec_helper"

# TODO: Remove these tests or move to a more appropriate place.

describe "ActiveRecord compatibility", orm: :active_record do
  include Helpers::Plugins
  include Helpers::Translates
  # Enable all plugins that are enabled by default pre v1.0
  plugins :active_record, :reader, :writer, :cache, :dirty, :presence, :query, :attribute_methods

  before { stub_const 'Post', Class.new(ActiveRecord::Base) }

  describe "#assign_attributes" do
    before { translates Post, :title, backend: :key_value, type: :string }
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
    before { translates Post, :title, backend: :key_value, type: :string }
    let!(:post) { Post.create(title: "foo title") }

    it "updates cache when translations association is modified directly" do
      expect(post.title).to eq("foo title")
      post.send(backend_for(post, :title).association_name).first.value = "association changed value"
      expect(post.title).to eq("association changed value")
      post.title = "writer changed value"
      expect(post.title).to eq("writer changed value")
      post.send(backend_for(post, :title).association_name).first.value = "association changed value"
      post.save
      expect(Post.first.title).to eq("association changed value")
    end

    it "resets cache when model is reloaded", active_record_geq: '5.0' do
      expect(post.mobility_backends[:title]).to receive(:clear_cache).once
      post.reload
    end
  end

  describe "dirty tracking" do
    before { translates Post, :title, backend: :key_value, type: :string }
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
    before { translates Post, :title, backend: :key_value, type: :string, fallbacks: true }
    let!(:post) { Post.create(title: "foo title") }

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
    before do
      translates Post, :title, backend: :key_value, type: :string
      translates Post, :content, backend: :key_value, type: :text
    end

    it "includes both original and translated attributes" do
      post = Post.new
      post.title = "foo"
      post.content = "bar"
      expect(post.attributes).to include_hash({ "published" => post.published, "id" => post.id, "title" => "foo", "content" => "bar" })
    end
  end

  describe "#translated_attributes" do
    before do
      translates Post, :title, backend: :key_value, type: :string
      translates Post, :content, backend: :key_value, type: :text
    end

    it "includes only translated attributes" do
      post = Post.new
      post.title = "foo"
      post.content = "bar"
      expect(post.translated_attributes).to eq({ "title" => "foo", "content" => "bar" })
    end
  end

  describe "#untranslated_attributes" do
    before do
      translates Post, :title, backend: :key_value, type: :string
      translates Post, :content, backend: :key_value, type: :text
    end

    it "includes only original attributes" do
      post = Post.new
      post.title = "foo"
      post.content = "bar"
      expect(post.untranslated_attributes).to include_hash({ "published" => post.published, "id" => post.id })
    end
  end

  describe "uniqueness validation" do
    it "works without any translated attributes" do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      translates Article, :title, backend: :key_value, type: :string
      Article.validates :slug, uniqueness: true

      article = Article.create(slug: "foo")
      expect(Article.new(slug: "bar")).to be_valid
      expect(Article.new(slug: "foo")).not_to be_valid
    end
  end

  describe "merging translated and untranslated scopes" do
    # regression for https://github.com/shioyama/mobility/issues/266
    it "returns correct result" do
      stub_const 'Comment', Class.new(ActiveRecord::Base)
      translates Comment, :content, backend: :column

      stub_const 'Article', Class.new(ActiveRecord::Base)
      Article.has_many :comments

      Article.create
      article = Article.create
      article.comments.create(content: "foo", published: true)
      other = Article.create
      other.comments.create(content: "foo", published: false)

      # It's necessary to dup the relation before querying on it after merging,
      # because Mobility uses Arel nodes when building queries and this sets a
      # flag causing ActiveRecord to raise an ImmutableRelation exception.
      #
      # See:
      # https://github.com/rails/rails/blob/fc5dd0b85189811062c85520fd70de8389b55aeb/activerecord/lib/active_record/relation/query_methods.rb#L923
      expect(Article.joins(:comments).merge(Comment.i18n.where(content: "foo")).dup.find_by(comments: { published: true })).to eq(article)
      expect(Article.joins(:comments).merge(Comment.i18n.where(content: "foo")).dup.find_by(comments: { published: false })).to eq(other)
    end
  end
end
