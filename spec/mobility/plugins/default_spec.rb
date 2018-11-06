require "spec_helper"
require "mobility/plugins/default"

describe Mobility::Plugins::Default do
  include Helpers::Plugins

  context "option = 'foo'" do
    plugin_setup default: 'default foo'

    describe "#read" do
      it "returns value if not nil" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, "foo"])
        expect(backend.read(:fr)).to eq([:fr, "foo"])
      end

      it "returns value if value is false" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, false])
        expect(backend.read(:fr)).to eq([:fr, false])
      end

      it "returns default if backend return value is nil" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, nil])
        expect(backend.read(:fr)).to eq([:fr, "default foo"])
      end

      it "returns value of default override if passed as option to reader" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, nil])
        expect(backend.read(:fr, default: "default bar")).to eq([:fr, "default bar"])
      end

      it "returns nil if passed default: nil as option to reader" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, nil])
        expect(backend.read(:fr, default: nil)).to eq([:fr, nil])
      end

      it "returns false if passed default: false as option to reader" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, nil])
        expect(backend.read(:fr, default: false)).to eq([:fr, false])
      end
    end
  end

  context "default is a Proc" do
    plugin_setup default: Proc.new { |attribute, locale, options| "#{attribute} in #{locale} with #{options[:this]}" }

    it "calls default with model and attribute as args if default is a Proc" do
      expect(listener).to receive(:read).once.with(:fr, this: 'option').and_return([:fr, nil])
      expect(backend.read(:fr, this: 'option')).to eq([:fr, "title in fr with option"])
    end

    it "calls default with model and attribute as args if default option is a Proc" do
      aggregate_failures do
        # with no arguments
        expect(listener).to receive(:read).once.with(:fr, this: 'option').and_return([:fr, nil])
        default_as_option = Proc.new { "default" }
        expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq([:fr, "default"])

        # with one argument
        expect(listener).to receive(:read).once.with(:fr, this: 'option').and_return([:fr, nil])
        default_as_option = Proc.new { |attribute| "default #{attribute}" }
        expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq([:fr, "default title"])

        # with two arguments
        expect(listener).to receive(:read).once.with(:fr, this: 'option').and_return([:fr, nil])
        default_as_option = Proc.new { |attribute, locale| "default #{attribute} #{locale}" }
        expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq([:fr, "default title fr"])

        # with three arguments
        expect(listener).to receive(:read).once.with(:fr, this: 'option').and_return([:fr, nil])
        default_as_option = Proc.new { |attribute, locale, options| "default #{attribute} #{locale} #{options[:this]}" }
        expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq([:fr, "default title fr option"])

        # with any arguments
        expect(listener).to receive(:read).once.with(:fr, this: 'option').and_return([:fr, nil])
        default_as_option = Proc.new { |attribute, **| "default #{attribute}" }
        expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq([:fr, "default title"])
      end
    end
  end
end
