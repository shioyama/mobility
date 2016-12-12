require 'spec_helper'

describe Mobility do
  it 'has a version number' do
    expect(Mobility::VERSION).not_to be nil
  end

  describe "including Mobility in class" do
    let!(:model) do
      model = stub_const 'MyModel', Class.new
      model.class_eval do
        def attributes
          { "foo" => "bar" }
        end
      end
      model
    end

    context "with no translated attributes" do
      it "does not include Attributes into model class" do
        expect(Mobility::Attributes).not_to receive(:new)
        model.include Mobility
      end

      it "defines translated_attribute_names as empty array" do
        model.include Mobility
        expect(MyModel.translated_attribute_names).to eq([])
      end

      it "defines Model.mobility as memoized wrapper" do
        model.include Mobility
        expect(MyModel.mobility).to be_a(Mobility::Wrapper)
        expect(MyModel.mobility).to be(MyModel.mobility)
      end
    end

    context "with translated attributes" do
      it "includes backend module into model class" do
        expect(Mobility::Attributes).to receive(:new).and_call_original
        model.include Mobility
        model.translates :title, backend: :null, foo: :bar
        backend_module = model.ancestors.find { |a| a.class == Mobility::Attributes }
        expect(backend_module).not_to be_nil
        expect(backend_module.attributes).to eq ["title"]
        expect(backend_module.options).to eq(foo: :bar)
      end

      it "defines translated_attribute_names" do
        model.include Mobility
        model.translates :title, backend: :null
        expect(MyModel.translated_attribute_names).to eq(["title"])
      end
    end
  end

  describe '.with_locale' do
    def perform_with_locale(locale)
      Thread.new do
        Mobility.with_locale(locale) do
          Thread.pass
          expect(locale).to eq(Mobility.locale)
        end
      end
    end

    it 'sets locale in a single thread' do
      perform_with_locale(:en).join
    end

    it 'sets independent locales in multiple threads' do
      threads = []
      threads << perform_with_locale(:en)
      threads << perform_with_locale(:fr)
      threads << perform_with_locale(:de)
      threads << perform_with_locale(:cz)
      threads << perform_with_locale(:pl)

      threads.each(&:join)
    end

    it "returns result" do
      expect(Mobility.with_locale(:ja) { |locale| "returned-#{locale}" }).to eq("returned-ja")
    end

    context "something blows up" do
      it "sets locale back" do
        Mobility.with_locale(:ja) { raise StandardError } rescue StandardError
        expect(Mobility.locale).to eq(:en)
      end
    end
  end

  describe ".locale" do
    it "returns locale if set" do
      Mobility.locale = :de
      expect(Mobility.locale).to eq(:de)
    end

    it "returns I18n.locale otherwise" do
      Mobility.locale = nil
      I18n.locale = :de
      expect(Mobility.locale).to eq(:de)
    end
  end

  describe '.locale=' do
    it "sets locale for locale in I18n.available_locales" do
      Mobility.locale = :fr
      expect(Mobility.locale).to eq(:fr)
    end

    it "converts string to symbol" do
      Mobility.locale = "fr"
      expect(Mobility.locale).to eq(:fr)
    end

    it "raises Mobility::InvalidLocale for locale not in I18n.available_locales" do
      expect {
        Mobility.locale = :es
      }.to raise_error(Mobility::InvalidLocale)
    end
  end

  describe '.normalize_locale' do
    it "normalizes locale to lowercase string underscores" do
      expect(Mobility.normalize_locale(:"pt-BR")).to eq("pt_br")
    end
  end

  describe '.config' do
    it 'initializes a new configuration' do
      expect(Mobility.config).to be_a(Mobility::Configuration)
    end

    it 'memoizes configuration' do
      expect(Mobility.config).to be(Mobility.config)
    end
  end

  describe ".configure" do
    it "yields configuration" do
      expect { |block|
        Mobility.configure &block
      }.to yield_with_args(Mobility.config)
    end
  end

  describe ".default_fallbacks" do
    it "delegates to config" do
      fallbacks = double("fallbacks")
      expect(Mobility.config).to receive(:default_fallbacks).and_return(fallbacks)
      expect(Mobility.default_fallbacks).to eq(fallbacks)
    end
  end
end
