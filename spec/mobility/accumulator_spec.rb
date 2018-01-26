require "spec_helper"

describe Mobility::Accumulator do
  let(:model_class) { double "model class" }
  describe "#<<" do
    it "appends module to modules" do
      attributes = double("attributes")
      accumulator = described_class.new
      accumulator << attributes
      expect(accumulator.modules).to eq([attributes])
    end
  end

  describe "#translated_attribute_names" do
    it "returns flattened array of module attributes" do
      module1 = double("attributes", names: ["foo", "bar"])
      module2 = double("attributes", names: ["baz"])
      accumulator = described_class.new
      accumulator << module1
      accumulator << module2
      expect(accumulator.translated_attribute_names).to eq(["foo", "bar", "baz"])
    end
  end
end
