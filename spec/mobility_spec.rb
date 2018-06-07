require 'spec_helper'

describe Mobility do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
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

    it "aliases mobility_accessor if Mobility.config.accessor_method is set" do
      expect(described_class.config).to receive(:accessor_method).and_return(:foo_translates)
      model.extend described_class
      expect { described_class.translates }.to raise_error(NoMethodError)
      model.foo_translates :title, backend: :null, foo: :bar
      expect(model.new.methods).to include :title
      expect(model.new.methods).to include :title=
    end

    it "does not alias mobility_accessor to anything if Mobility.config.accessor_method is falsy" do
      expect(described_class.config).to receive(:accessor_method).and_return(nil)
      model.extend described_class
      expect { described_class.translates }.to raise_error(NoMethodError)
    end

    context "with translated attributes" do
      it "includes backend module into model class" do
        expect(described_class::Attributes).to receive(:new).
          with(:title, { method: :accessor, backend: :null, foo: :bar }).
          and_call_original
        model.extend described_class
        model.translates :title, backend: :null, foo: :bar
      end

      it "defines translated_attribute_names" do
        model.extend described_class
        model.translates :title, backend: :null
        expect(MyModel.translated_attribute_names).to eq(["title"])
      end

      context "model subclass" do
        it "inherits translated_attribute_names" do
          model.extend described_class
          model.translates :title, backend: :null
          subclass = Class.new(model)
          expect(subclass.translated_attribute_names).to eq(["title"])
        end

        it "defines new translated attributes independently of superclass" do
          model.extend described_class
          model.translates :title, backend: :null
          subclass = Class.new(model)
          subclass.translates :content, backend: :null

          expect(model.translated_attribute_names).to eq(["title"])
          expect(subclass.translated_attribute_names).to match_array(["title", "content"])
        end
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
  end

  describe '.config' do
    it 'initializes a new configuration' do
      expect(described_class.config).to be_a(described_class::Configuration)
    end

    it 'memoizes configuration' do
      expect(described_class.config).to be(described_class.config)
    end
  end

  describe ".configure" do
    it "yields configuration" do
      expect { |block|
        described_class.configure &block
      }.to yield_with_args(described_class.config)
    end
  end

  # TODO: remove default_fallbacks in v1.0
  %w[accessor_method query_method default_fallbacks new_fallbacks default_accessor_locales].each do |delegated_method|
    describe ".#{delegated_method}" do
      it "delegates to config" do
        expect(described_class.config).to receive(delegated_method).and_return("foo")
        expect(described_class.send(delegated_method)).to eq("foo")
      end
    end
  end
end
