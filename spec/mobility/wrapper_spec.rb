require "spec_helper"

describe Mobility::Wrapper do
  let(:model_class) { double "model class" }
  describe "#<<" do
    it "appends module to modules" do
      attributes = double("attributes")
      wrapper = Mobility::Wrapper.new(model_class)
      wrapper << attributes
      expect(wrapper.modules).to eq([attributes])
    end
  end

  describe "#translated_attribute_names" do
    it "returns flattened array of module attributes" do
      module1 = double("attributes", names: ["foo", "bar"])
      module2 = double("attributes", names: ["baz"])
      wrapper = Mobility::Wrapper.new(model_class)
      wrapper << module1
      wrapper << module2
      expect(wrapper.translated_attribute_names).to eq(["foo", "bar", "baz"])
    end
  end
end
