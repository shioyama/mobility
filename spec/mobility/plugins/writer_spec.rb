require "spec_helper"
require "mobility/plugins/writer"

describe Mobility::Plugins::Writer do
  include Helpers::Plugins

  plugin_setup writer: true

  describe "getters" do
    let(:instance) { model_class.new }

    it "correctly maps setter method for translated attribute to backend" do
      expect(Mobility).to receive(:locale).and_return(:de)
      expect(listener).to receive(:write).with(:de, "foo", any_args)
      expect(instance.title = "foo").to eq("foo")
    end

    it "correctly maps locale through setter options and converts to boolean" do
      expect(listener).to receive(:write).with(:fr, "foo", any_args).and_return("foo")
      expect(instance.send(:title=, "foo", locale: :fr)).to eq("foo")
    end

    it "correctly maps other options to getter" do
      expect(Mobility).to receive(:locale).and_return(:de)
      expect(listener).to receive(:write).with(:de, "foo", someopt: "someval").and_return("foo")
      instance.send(:title=, "foo", someopt: "someval")
    end

    it "raises Mobility::InvalidLocale if write is called with locale not in available locales" do
      expect {
        instance.send(:title=, 'foo', locale: :ru)
      }.to raise_error(Mobility::InvalidLocale)
    end
  end

  describe "super option" do
    let(:instance) { model_class.new }
    let(:model_class) do
      Class.new.tap do |klass|
        mod = Module.new do
          def title=(title)
            "set title to #{title}"
          end
        end
        klass.include attributes, mod
        klass
      end
    end

    it "calls original getter when super: true passed as option" do
      expect(instance.send(:title=, 'foo', super: true)).to eq("set title to foo")
    end
  end
end

