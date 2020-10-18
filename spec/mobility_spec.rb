require 'spec_helper'

describe Mobility, orm: :none do
  it 'has a version number' do
    expect(described_class.gem_version).not_to be nil
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

    context "with translated attributes" do
      it "includes backend module into model class" do
        klass = Class.new(described_class::Translations)
        Mobility.translates_with(klass)
        expect(klass).to receive(:new).
          with(:title, backend: :null, foo: :bar).
          and_call_original
        model.extend described_class
        model.translates :title, backend: :null, foo: :bar
      end
    end
  end

  describe '.with_locale' do
    def perform_with_locale(locale)
      Thread.new do
        described_class.with_locale(locale) do
          Thread.pass
          expect(locale).to eq(described_class.locale)
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
      expect(described_class.with_locale(:ja) { |locale| "returned-#{locale}" }).to eq("returned-ja")
    end

    context "something blows up" do
      it "sets locale back" do
        described_class.with_locale(:ja) { raise StandardError } rescue StandardError
        expect(described_class.locale).to eq(:en)
      end
    end
  end

  describe ".locale" do
    it "returns locale if set" do
      described_class.locale = :de
      expect(described_class.locale).to eq(:de)
    end

    it "returns I18n.locale otherwise" do
      described_class.locale = nil
      I18n.locale = :de
      expect(described_class.locale).to eq(:de)
    end
  end

  describe '.locale=' do
    it "sets locale for locale in I18n.available_locales" do
      described_class.locale = :fr
      expect(described_class.locale).to eq(:fr)
    end

    it "converts string to symbol" do
      described_class.locale = "fr"
      expect(described_class.locale).to eq(:fr)
    end

    it "raises Mobility::InvalidLocale for locale not in I18n.available_locales" do
      expect {
        described_class.locale = :es
      }.to raise_error(described_class::InvalidLocale)
    end

    context "I18n.enforce_available_locales = false" do
      around do |example|
        I18n.enforce_available_locales = false
        example.run
        I18n.enforce_available_locales = true
      end

      it "does not raise Mobility::InvalidLocale for locale not in I18n.available_locales" do
        expect {
          described_class.locale = :es
        }.not_to raise_error
      end
    end
  end

  describe ".available_locales" do
    around do |example|
      @available_locales = I18n.available_locales
      I18n.available_locales = [:en, :pt]
      example.run
      I18n.available_locales = @available_locales
    end

    it "defaults to I18n.available_locales" do
      expect(described_class.available_locales).to eq([:en, :pt])
    end

    # @note Required since model may be loaded in initializer before Rails has
    #   updated I18n.available_locales.
    it "uses Rails i18n locales if Rails application is loaded" do
      allow(Rails).to receive_message_chain(:application, :config, :i18n, :available_locales).
        and_return([:ru, :cn])
      expect(described_class.available_locales).to eq([:ru, :cn])
    end if defined?(Rails)
  end

  describe '.normalize_locale' do
    it "normalizes locale to lowercase string underscores" do
      expect(described_class.normalize_locale(:"pt-BR")).to eq("pt_br")
    end

    it "normalizes current locale if passed no argument" do
      described_class.with_locale(:"pt-BR") do
        aggregate_failures do
          expect(described_class.normalize_locale).to eq("pt_br")
          expect(described_class.normalized_locale).to eq("pt_br")
        end
      end
    end

    it "normalizes locales with multiple dashes" do
      expect(described_class.normalize_locale(:"foo-bar-baz")).to eq("foo_bar_baz")
    end
  end

  describe '.normalize_locale_accessor' do
    it "normalizes accessor to use lowercase locale with underscores" do
      expect(described_class.normalize_locale_accessor(:foo, :"pt-BR")).to eq("foo_pt_br")
    end

    it "defaults locale to Mobility.locale" do
      described_class.with_locale(:fr) do
        expect(described_class.normalize_locale_accessor(:foo)).to eq("foo_fr")
      end
    end

    it "raises ArgumentError for invalid attribute or locale" do
      expect { described_class.normalize_locale_accessor(:"a-*-b") }.
        to raise_error(ArgumentError, "\"a-*-b_en\" is not a valid accessor")
    end
  end

  describe ".configure" do
    it "yields the translation class, or creates one if not defined" do
      klass = Class.new
      described_class.translates_with(klass)
      expect { |block|
        described_class.configure &block
      }.to yield_with_args(klass)
    end
  end

  describe "#translates" do
    it "delegates to translation_class" do
      translations_class = Class.new(Mobility::Translations)
      Mobility.translates_with(translations_class)
      expect(translations_class).to receive(:new).once.with("title", foo: "bar").and_return(mod = Module.new)

      klass = Class.new
      klass.extend Mobility
      klass.translates "title", foo: "bar"
      expect(klass.included_modules).to include(mod)
    end
  end

  describe ".translates_with" do
    it "sets translations_class" do
      klass = Class.new(Mobility::Translations)
      described_class.translates_with(klass)
      expect(described_class.translations_class).to eq(klass)
    end
  end

  describe "#default_backend" do
    it "defaults to nil" do
      translations_class = Class.new(Mobility::Translations)
      subject.translates_with translations_class
      expect(subject.default_backend).to eq(nil)
    end
  end
end
