require "spec_helper"

describe Mobility::Backend::Sequel::Columns, orm: :sequel do
  extend Helpers::Sequel

  let(:attributes) { %w[content author] }
  let(:options) { {} }
  let(:backend) { described_class.new(comment, attributes.first, options) }
  let(:comment) do
    Comment.create(content_en: "Good post!",
                   content_ja: "なかなか面白い記事",
                   content_pt_br: "Olá")
  end

  before do
    stub_const 'Comment', Class.new(Sequel::Model)
    Comment.dataset = DB[:comments]
    Comment.include Mobility
    Comment.translates *attributes, backend: :columns, cache: false
  end

  subject { comment }

  describe "#read" do
    it "returns attribute in locale from appropriate column" do
      expect(backend.read(:en)).to eq("Good post!")
      expect(backend.read(:ja)).to eq("なかなか面白い記事")
    end

    it "handles dashed locales" do
      expect(backend.read(:"pt-BR")).to eq("Olá")
    end
  end

  describe "#write" do
    it "assigns to appropriate columnn" do
      backend.write(:en, "Crappy post!")
      backend.write(:ja, "面白くない")
      expect(comment.content_en).to eq("Crappy post!")
      expect(comment.content_ja).to eq("面白くない")
    end

    it "handles dashed locales" do
      backend.write(:"pt-BR", "Olá Olá")
      expect(comment.content_pt_br).to eq "Olá Olá"
    end
  end

  describe "Model accessors" do
    include_accessor_examples "Post"
  end

  describe "with locale accessors" do
    it "still works as usual" do
      Comment.translates *attributes, backend: :columns, cache: false, locale_accessors: true
      backend.write(:en, "Crappy post!")
      expect(comment.content_en).to eq("Crappy post!")
    end
  end

  describe "mobility dataset (.i18n)" do
    include_querying_examples 'Comment', :content, :author
  end
end
