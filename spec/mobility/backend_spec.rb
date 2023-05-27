require 'spec_helper'
require 'mobility/plugins/backend'

describe Mobility::Backend do
  context "included in backend" do
    let(:backend_class) { MyBackend }
    let(:backend_double) { double("backend") }
    let(:attribute) { "title" }
    let(:model) { double("model") }
    let(:backend) { backend_class.new(model, attribute) }
    before do
      backend_double_ = backend_double
      backend = stub_const 'MyBackend', Class.new
      backend.class_eval do
        define_method :read do |locale, options = {}|
          backend_double_.read(locale, options)
        end

        define_method :write do |locale, value, options = {}|
          backend_double_.read(locale, options)
        end
      end
      backend.include described_class
    end

    it "assigns attribute" do
      expect(backend.attribute).to eq(attribute)
    end

    it "assigns model" do
      expect(backend.model).to eq(model)
    end

    describe "#present?" do
      it "returns true if backend.read(locale) return non-blank value" do
        expect(backend_double).to receive(:read).with(:en, {}).and_return("foo")
        expect(backend.present?(:en)).to eq(true)
      end

      it "returns false if backend.read(locale) returns blank value" do
        expect(backend_double).to receive(:read).with(:en, {}).and_return("")
        expect(backend.present?(:en)).to eq(false)
      end
    end

    describe "#==" do
      it "returns true if two backends have the same class, model and attributes" do
        expect(backend_class.new(model, attribute)).to eq(backend)
      end

      it "returns false if backends have different classes" do
        expect(Class.new(backend_class).new(model, attribute)).not_to eq(backend)
      end

      it "returns false if backends have different attributes" do
        expect(backend_class.new(model, "foo")).not_to eq(backend)
      end

      it "returns false if backends have different models" do
        expect(backend_class.new(double(:other_model), attribute)).not_to eq(backend)
      end
    end

    describe "#each" do
      it "returns nothing by default" do
        backend = backend_class.new(model, attribute)
        expect(backend.each).to eq(nil)
      end

      it "yields translations to each_locale if method is defined" do
        backend_class.class_eval do
          def each_locale
            yield :ja
            yield :en
          end
        end
        backend = backend_class.new(model, attribute)

        translations = backend.inject([]) do |translations, translation|
          translations << translation
          translations
        end

        aggregate_failures "translation locales" do
          expect(translations.first.locale).to eq(:ja)
          expect(translations.last.locale).to eq(:en)
        end

        options = double("options")

        aggregate_failures "translation reads" do
          expect(backend).to receive(:read).with(:ja, options).and_return("ja val")
          expect(translations.first.read(options)).to eq("ja val")
          expect(backend).to receive(:read).with(:en, options).and_return("en val")
          expect(translations.last.read(options)).to eq("en val")
        end

        aggregate_failures "translation writes" do
          expect(backend).to receive(:write).with(:ja, "ja val", options)
          expect(translations.first.write("ja val", options))
          expect(backend).to receive(:write).with(:en, "en val", options)
          expect(translations.last.write("en val", options))
        end
      end
    end

    describe "#locales" do
      it "maps locales to array" do
        backend_class.class_eval do
          def each_locale
            yield :ja
            yield :en
          end
        end
        backend = backend_class.new(model, attribute)
        expect(backend.locales).to eq([:ja, :en])
      end
    end

    describe "enumerable methods" do
      it "includes Enumerable methods" do
        expect(backend_class.ancestors).to include(Enumerable)
      end
    end

    describe ".setup" do
      context "with two block arguments" do
        before do
          backend_class.setup do |attributes, options|
            def self.foo
              "foo"
            end
            def bar
              "bar"
            end
            define_method :my_attributes do
              attributes
            end
            define_method :my_options do
              options
            end
          end
        end

        it "stores setup as block which is called in model class" do
          model_class = Class.new
          backend_class.build_subclass(model_class, foo: "bar").setup_model(model_class, ["title"])
          expect(model_class.foo).to eq("foo")
          expect(model_class.new.bar).to eq("bar")
        end

        it "passes attributes and options to setup block when called on class" do
          model_class = Class.new
          backend_class.build_subclass(model_class, foo: "bar").setup_model(model_class, ["title"])
          expect(model_class.new.my_attributes).to eq(["title"])
          expect(model_class.new.my_options).to eq({ foo: "bar" })
        end

        it "assigns setup block to descendants" do
          model_class = Class.new
          subclass = backend_class.build_subclass(model_class, foo: "bar")
          subclass.setup_model(model_class, ["title"])
          expect(model_class.foo).to eq("foo")
        end

        it "concatenates blocks when called multiple times" do
          backend_class.setup do |attributes, options|
            def self.foo
              "foo2"
            end
            define_method :baz do
              "#{attributes.join} baz"
            end
            def self.foobar
              "foobar"
            end
          end
          model_class = Class.new
          backend_class.build_subclass(model_class, foo: "bar").setup_model(model_class, ["title", "content"])

          aggregate_failures do
            expect(model_class.foo).to eq("foo2")
            expect(model_class.new.baz).to eq("titlecontent baz")
            expect(model_class.foobar).to eq("foobar")
          end
        end
      end

      context "with 3 block arguments" do
        before do
          backend_class.setup do |attributes, options, klass|
            define_method :my_attributes do
              attributes
            end
            define_method :my_options do
              options
            end
            define_method :my_backend_class do
              klass
            end
          end
        end

        it "passes configured backend class as third argument" do
          model_class = Class.new
          configured_backend_class = backend_class.build_subclass(model_class, foo: "bar")
          configured_backend_class.setup_model(model_class, ["title"])

          model = model_class.new

          expect(model.my_attributes).to eq(["title"])
          expect(model.my_options).to eq({ foo: "bar" })
          expect(model.my_backend_class).to eq(configured_backend_class)
        end

        it "works with block concatenation" do
          backend_class.setup do |attributes, options|
            define_method :my_attributes_2 do
              attributes
            end
          end
          model_class = Class.new
          configured_backend_class = backend_class.build_subclass(model_class, foo: "bar")
          configured_backend_class.setup_model(model_class, ["title"])

          model = model_class.new

          aggregate_failures do
            expect(model.my_attributes).to eq(["title"])
            expect(model.my_options).to eq({ foo: "bar" })
            expect(model.my_backend_class).to eq(configured_backend_class)
          end
        end
      end
    end

    describe ".build_subclass" do
      it "raises when subclassed again" do
        model_class = Class.new
        subclass = backend_class.build_subclass(model_class, foo: "bar")
        expect { Class.new(subclass) }.to raise_error(Mobility::Backend::ConfiguredError)
      end
    end

    describe "methods which raise unless called on configured subclass" do
      it "raises when unconfigured" do
        expect { backend_class.options }.to raise_error(Mobility::Backend::UnconfiguredError)
        expect { backend_class.model_class }.to raise_error(Mobility::Backend::UnconfiguredError)
        expect { backend_class.setup_model(Class.new, {}) }.to raise_error(Mobility::Backend::UnconfiguredError)
      end

      it "returns value when configured" do
        model_class = double("model class")
        options = {}
        subclass = backend_class.build_subclass(model_class, options)
        expect(subclass.model_class).to eq(model_class)
        expect(subclass.options).to eq(options)
      end
    end
  end

  describe "#inspect on configured backend" do
    it "returns superclass name" do
      backend = stub_const 'MyBackend', Class.new
      model_class = stub_const 'Model', Class.new
      backend.include(described_class)
      options = { foo: "bar" }
      subclass = backend.build_subclass(model_class, options)
      expect(subclass.inspect).to match(/MyBackend/)
    end
  end
end
