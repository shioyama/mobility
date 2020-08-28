require "spec_helper"
require "mobility/plugins/reader"

describe Mobility::Plugins::Reader, type: :plugin do
  plugins :reader
  plugin_setup :title

  describe "getters" do
    let(:instance) { model_class.new }

    it "correctly maps getter method for translated attribute to backend" do
      expect(Mobility).to receive(:locale).and_return(:de)
      expect(listener).to receive(:read).with(:de, any_args).and_return("foo")
      expect(instance.title).to eq("foo")
    end

    it "correctly maps presence method for translated attribute to backend" do
      expect(Mobility).to receive(:locale).and_return(:de)
      expect(listener).to receive(:read).with(:de, any_args).and_return("foo")
      expect(instance.title?).to eq(true)
    end

    it "correctly maps locale through getter options and converts to boolean" do
      expect(listener).to receive(:read).with(:fr, any_args).and_return("foo")
      expect(instance.title(locale: :fr)).to eq("foo")
    end

    it "correctly handles string-valued locale option" do
      expect(listener).to receive(:read).with(:fr, any_args).and_return("foo")
      expect(instance.title(locale: 'fr')).to eq("foo")
    end

    it "correctly maps other options to getter" do
      expect(Mobility).to receive(:locale).and_return(:de)
      expect(listener).to receive(:read).with(:de, someopt: "someval").and_return("foo")
      expect(instance.title(someopt: "someval")).to eq("foo")
    end

    it "raises Mobility::InvalidLocale if called with locale not in available locales" do
      expect {
        instance.title(locale: :ru)
      }.to raise_error(Mobility::InvalidLocale)
    end
  end

  describe "super option" do
    let(:instance) { model_class.new }
    let(:model_class) do
      Class.new.tap do |klass|
        mod = Module.new do
          def title
            "title"
          end

          def title?
            "title?"
          end
        end
        klass.include translations, mod
        klass
      end
    end

    it "calls original getter when super: true passed as option" do
      expect(instance.title(super: true)).to eq("title")
    end

    it "calls original presence when super: true passed as option" do
      expect(instance.title?(super: true)).to eq("title?")
    end
  end
end
