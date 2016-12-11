require "spec_helper"

describe Mobility::Translates do
  before do
    stub_const('MyClass', Class.new).extend(Mobility::Translates)
  end

  describe ".translates" do
    it "includes new Attributes module" do
      attributes = Module.new
      expect(Mobility::Attributes).to receive(:new).with(:accessor, :title, :content, { model_class: MyClass }).and_return(attributes)
      MyClass.translates :title, :content
    end

    it "yields backend to block if block given" do
      attributes = Module.new do
        def self.backend; end
      end
      backend = double("backend")
      expect(attributes).to receive(:backend).and_return(backend)
      expect(backend).to receive(:foo).with("bar")
      allow(Mobility::Attributes).to receive(:new).and_return(attributes)
      MyClass.translates :title do |backend|
        backend.foo("bar")
      end
    end
  end
end
