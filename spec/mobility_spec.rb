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

    it "aliases mobility_accessor if Mobility.config.accessor_method is set" do
      expect(Mobility.config).to receive(:accessor_method).and_return(:foo_translates)
      model.include Mobility
      expect { Mobility.translates }.to raise_error(NoMethodError)
      model.foo_translates :title, backend: :null, foo: :bar
      expect(model.new.methods).to include :title
      expect(model.new.methods).to include :title=
    end

    it "does not alias mobility_accessor to anything if Mobility.config.accessor_method is falsy" do
      expect(Mobility.config).to receive(:accessor_method).and_return(nil)
      model.include Mobility
      expect { Mobility.translates }.to raise_error(NoMethodError)
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
        expect(backend_module.options).to eq(foo: :bar, model_class: MyModel)
      end

      it "defines translated_attribute_names" do
        model.include Mobility
        model.translates :title, backend: :null
        expect(MyModel.translated_attribute_names).to eq(["title"])
      end

      context "model subclass" do
        it "inherits translated_attribute_names" do
          model.include Mobility
          model.translates :title, backend: :null
          subclass = Class.new(model)
          expect(subclass.translated_attribute_names).to eq(["title"])
        end

        it "defines new translated attributes independently of superclass" do
          model.include Mobility
          model.translates :title, backend: :null
          subclass = Class.new(model)
          subclass.translates :content, backend: :null

          expect(model.translated_attribute_names).to eq(["title"])
          expect(subclass.translated_attribute_names).to match_array(["title", "content"])
        end
      end
    end

    describe "duplicating model" do
      let(:instance) do
        model.include Mobility
        model.translates :title, backend: :null
        # call title getter once to memoize backend
        model.new.tap { |instance| instance.title }
      end

      it "resets memoized backends" do
        other = instance.dup
        expect(other.title_backend).not_to eq(instance.title_backend)
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

    context "I18n.enforce_available_locales = false" do
      around do |example|
        I18n.enforce_available_locales = false
        example.run
        I18n.enforce_available_locales = true
      end

      it "does not raise Mobility::InvalidLocale for locale not in I18n.available_locales" do
        expect {
          Mobility.locale = :es
        }.not_to raise_error
      end
    end
  end

  describe '.normalize_locale' do
    it "normalizes locale to lowercase string underscores" do
      expect(Mobility.normalize_locale(:"pt-BR")).to eq("pt_br")
    end

    it "normalizes current locale if passed no argument" do
      Mobility.with_locale(:"pt-BR") do
        aggregate_failures do
          expect(Mobility.normalize_locale).to eq("pt_br")
          expect(Mobility.normalized_locale).to eq("pt_br")
        end
      end
    end
  end

  describe '.normalize_locale_accessor' do
    it "normalizes accessor to use lowercase locale with underscores" do
      expect(Mobility.normalize_locale_accessor(:foo, :"pt-BR")).to eq("foo_pt_br")
    end

    it "defaults locale to Mobility.locale" do
      Mobility.with_locale(:fr) do
        expect(Mobility.normalize_locale_accessor(:foo)).to eq("foo_fr")
      end
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

  %w[accessor_method query_method default_fallbacks default_accessor_locales].each do |delegated_method|
    describe ".#{delegated_method}" do
      it "delegates to config" do
        expect(Mobility.config).to receive(delegated_method).and_return("foo")
        expect(Mobility.send(delegated_method)).to eq("foo")
      end
    end
  end
end
