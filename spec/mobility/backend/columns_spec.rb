require "spec_helper"

describe Mobility::Backend::Columns do
  let(:attribute) { "content" }
  let(:options) { {} }
  let(:backend) { described_class.new(comment, attribute, options) }
  let(:comment) do
    Comment.create(content_en: "Good post!",
                   content_ja: "なかなか面白い記事",
                   content_pt_br: "Olá")
  end

  before do
    stub_const 'Comment', Class.new(ActiveRecord::Base)
    Comment.include Mobility
    Comment.translates attribute, backend: :columns, cache: false
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

  describe "Model.find_by_<translated attribute>" do
    let!(:comment_1) do
      Comment.create(content_en: "Good post!", content_ja: "面白い記事")
    end
    let!(:comment_2) do
      Comment.create(content_en: "Crappy post!", content_ja: "面白くない!")
    end

    it "finds by column with locale suffix" do
      expect(Comment.find_by_content("Good post!")).to eq(comment_1)
      expect(Comment.find_by_content("Crappy post!")).to eq(comment_2)
      Mobility.with_locale(:ja) do
        expect(Comment.find_by_content("面白い記事")).to eq(comment_1)
        expect(Comment.find_by_content("面白くない!")).to eq(comment_2)
      end
    end

    it "does not return result for other locale" do
      Mobility.with_locale(:ja) do
        expect(Comment.find_by_content("Good post!")).to be_nil
        expect(Comment.find_by_content("Crappy post!")).to be_nil
      end
    end
  end

  describe "with locale accessors" do
    it "still works as usual" do
      Comment.translates attribute, backend: :columns, cache: false, locale_accessors: true
      backend.write(:en, "Crappy post!")
      expect(comment.content_en).to eq("Crappy post!")
    end
  end
end
