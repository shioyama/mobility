require "spec_helper"

describe Mobility::ActiveModel::AttributeMethods, orm: :active_record do
  before do
    model = stub_const 'BaseModel', Class.new
    model.class_eval do
      def attributes; { "untranslated" => "bar" }; end
    end
    mobility_model = stub_const 'MobilityModel', Class.new(BaseModel)
    klass = described_class
    mobility_model.class_eval do
      def self.translated_attribute_names; ["title"]; end
      def title; "foo"; end
      include klass
    end
  end

  subject { MobilityModel.new }

  describe "#translated_attribute_names" do
    its(:translated_attribute_names) { should == ["title"] }
  end

  describe "#translated_attributes" do
    it "returns hash of translated attribute names/values" do
      expect(subject.translated_attributes).to eq(
        {
          "title" => "foo"
        }
      )
    end
  end

  describe "#attributes" do
    it "adds translated attributes to normal attributes" do
      expect(subject.attributes).to eq(
        {
          "untranslated" => "bar",
          "title" => "foo"
        }
      )
    end
  end
end
