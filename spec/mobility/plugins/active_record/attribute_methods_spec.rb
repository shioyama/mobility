require "spec_helper"

describe Mobility::Plugins::ActiveRecord::AttributeMethods, orm: :active_record do
  before do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.extend Mobility
    Article.class_eval do
      extend Mobility
      translates :title, backend: :null, attribute_methods: true

      def title
        "foo"
      end
    end
  end
  let(:untranslated_attributes) do
    {
      "id" => nil,
      "slug" => nil,
      "published" => nil,
      "created_at" => nil,
      "updated_at" => nil
    }
  end

  subject { Article.new }

  describe "#translated_attributes" do
    it "returns hash of translated attribute names/values" do
      expect(subject.translated_attributes).to eq("title" => "foo")
    end
  end

  describe "#attributes" do
    it "adds translated attributes to normal attributes" do
      expect(subject.attributes).to eq(
        untranslated_attributes.merge("title" => "foo")
      )
    end
  end

  describe "#untranslated_attributes" do
    it "returns original value of attributes method" do
      expect(subject.untranslated_attributes).to eq(untranslated_attributes)
    end
  end
end if Mobility::Loaded::ActiveRecord
