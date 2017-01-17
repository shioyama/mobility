require "spec_helper"

describe Mobility::Backend::ActiveRecord::Column, orm: :active_record do
  extend Helpers::ActiveRecord

  let(:attributes) { %w[content author] }
  let(:options) { {} }
  let(:backend) { described_class.new(comment, attributes.first, options) }
  let(:comment) do
    Comment.create(content_en: "Good post!",
                   content_ja: "なかなか面白い記事",
                   content_pt_br: "Olá")
  end

  before do
    stub_const 'Comment', Class.new(ActiveRecord::Base)
    Comment.include Mobility
    Comment.translates *attributes, backend: :column, cache: false
  end

  subject { comment }

  describe "#read" do
    it "returns attribute in locale from appropriate column" do
      aggregate_failures do
        expect(backend.read(:en)).to eq("Good post!")
        expect(backend.read(:ja)).to eq("なかなか面白い記事")
      end
    end

    it "handles dashed locales" do
      expect(backend.read(:"pt-BR")).to eq("Olá")
    end
  end

  describe "#write" do
    it "assigns to appropriate columnn" do
      backend.write(:en, "Crappy post!")
      backend.write(:ja, "面白くない")

      aggregate_failures do
        expect(comment.content_en).to eq("Crappy post!")
        expect(comment.content_ja).to eq("面白くない")
      end
    end

    it "handles dashed locales" do
      backend.write(:"pt-BR", "Olá Olá")
      expect(comment.content_pt_br).to eq "Olá Olá"
    end
  end

  describe "Model accessors" do
    include_accessor_examples 'Comment', :content, :author
  end

  describe "with locale accessors" do
    it "still works as usual" do
      Comment.translates *attributes, backend: :column, cache: false, locale_accessors: true
      backend.write(:en, "Crappy post!")
      expect(comment.content_en).to eq("Crappy post!")
    end
  end

  describe "with dirty" do
    it "still works as usual" do
      Comment.translates *attributes, backend: :column, cache: false, dirty: true
      backend.write(:en, "Crappy post!")
      expect(comment.content_en).to eq("Crappy post!")
    end

    it "tracks changed attributes" do
      Comment.translates *attributes, backend: :column, cache: false, dirty: true
      comment = Comment.new

      aggregate_failures do
        expect(comment.content).to eq(nil)
        expect(comment.changed?).to eq(false)
        expect(comment.changed).to eq([])
        expect(comment.changes).to eq({})

        comment.content = "foo"
        expect(comment.content).to eq("foo")
        expect(comment.changed?).to eq(true)
        expect(comment.changed).to eq(["content_en"])
        expect(comment.changes).to eq({ "content_en" => [nil, "foo"] })
      end
    end
  end

  describe "mobility scope (.i18n)" do
    include_querying_examples 'Comment', :content, :author
  end
end
