require "spec_helper"

describe "Mobility::Sequel::TextTranslation", orm: :sequel do
  let(:described_class) { Mobility::Sequel::TextTranslation }
  before do
    stub_const 'Post', Class.new(Sequel::Model)
    Post.dataset = DB[:posts]
  end

  describe "#translatable" do
    it "gets translatable model" do
      post = Post.create
      translation = described_class.create(
        translatable_id: post.id,
        translatable_type: "Post",
        locale: "en",
        key: "content",
        value: "some content"
      )
      expect(translation.translatable).to eq(post)
      expect(translation.translatable).to eq(post)
    end
  end

  describe "#translatable=" do
    it "sets translatable model" do
      post = Post.create
      translation = described_class.new(
        locale: "en",
        key: "content",
        value: "some content"
      )
      translation.translatable = post
      translation.save
      translation.reload
      expect(translation.translatable).to eq(post)
    end
  end
end
