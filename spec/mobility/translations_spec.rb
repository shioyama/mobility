require "spec_helper"

describe Mobility::Translations, orm: :none do
  include Helpers::Backend
  before { stub_const 'Article', Class.new }

  let(:model_class) { Article }

  describe "including Translations in a model" do
    describe "model class methods" do
      describe ".mobility_attributes" do
        it "returns attribute names" do
          model_class.include described_class.new("title", "content")
          model_class.include described_class.new("foo")

          expect(model_class.mobility_attributes).to match_array(["title", "content", "foo"])
        end

        it "only returns unique attributes" do
          model_class.include described_class.new("title")
          model_class.include described_class.new("title")

          expect(model_class.mobility_attributes).to eq(["title"])
        end
      end

      describe ".mobility_attribute?" do
        it "returns true if and only if attribute name is translated" do
          names = %w[title content]
          model_class.include described_class.new(*names)
          names.each do |name|
            expect(model_class.mobility_attribute?(name)).to eq(true)
            expect(model_class.mobility_attribute?(name.to_sym)).to eq(true)
          end
          expect(model_class.mobility_attribute?("foo")).to eq(false)
        end
      end
    end
  end

  describe "#inspect" do
    it "returns attribute names" do
      attributes = described_class.new("title", "content")
      expect(attributes.inspect).to eq("#<Translations @names=title, content>")
    end
  end
end
