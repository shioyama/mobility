require "spec_helper"

describe Mobility::Accumulator do
  let(:model_class) { double "model class" }
  let(:subject) { described_class.new }

  describe "#<<" do
    it "appends module to modules" do
      attributes = Mobility::Attributes.new(backend: :null)
      subject << attributes
      expect(subject.modules).to eq([attributes])
    end
  end

  describe "#translated_attribute_names" do
    it "returns flattened array of module attributes" do
      module1 = Mobility::Attributes.new("foo", "bar", backend: :null)
      module2 = Mobility::Attributes.new("baz", backend: :null)
      subject << module1
      subject << module2
      expect(subject.translated_attribute_names).to eq(["foo", "bar", "baz"])
    end
  end

  describe "#backends" do
    it "returns backend class for given attribute name" do
      attributes = Mobility::Attributes.new("foo", "bar", backend: :null)
      Class.new { include Mobility }.include(attributes)
      subject << attributes

      expect(subject.backends[:foo]).to be < Mobility::Backends::Null
      expect(subject.backends[:bar]).to be < Mobility::Backends::Null
    end
  end
end
