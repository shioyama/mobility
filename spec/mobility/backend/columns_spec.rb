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
end
