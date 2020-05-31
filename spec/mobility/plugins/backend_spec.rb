require "spec_helper"
require "mobility/plugins/writer"

describe Mobility::Plugins::Backend do
  include Helpers::Plugins

  plugin_setup backend: true

  # Override default helper-defined model_class which has attributes module
  # pre-included, so we can explicitly include it in specs.
  let(:model_class) { Class.new }

  describe "#included" do
    it "calls with_options on backend class with options merged with default options" do
      expect(backend_class).to receive(:with_options).with(hash_including(foo: "bar", model_class: model_class)).and_return(Class.new(backend_class))
      attributes = attributes_class.new("title", backend: backend_class, foo: "bar")
      model_class.include attributes
    end

    it "assigns options to backend class" do
      attributes = attributes_class.new("title", backend: backend_class, foo: "bar")
      model_class.include attributes
      expect(attributes.backend_class.options).to eq(Mobility.default_options.merge(backend: backend_class, model_class: model_class, foo: "bar"))
    end

    it "freezes backend options after inclusion into model class" do
      attributes = attributes_class.new("title", backend: backend_class)
      model_class.include attributes
      expect(backend_class.options).to be_frozen
    end

    it "calls setup_model on backend class with model_class and attributes" do
      expect(backend_class).to receive(:setup_model).with(model_class, ["title"])
      model_class.include attributes_class.new("title", backend: backend_class)
    end

    describe ".mobility_backend_class" do
      it "returns backend class for attribute" do
        backend_class1 = Class.new
        backend_class1.include(Mobility::Backend)
        backend_class2 = Class.new
        backend_class2.include(Mobility::Backend)

        mod1 = attributes_class.new("title", "content", backend: backend_class1)
        mod2 = attributes_class.new("subtitle", backend: backend_class2)

        model_class.include mod1
        model_class.include mod2

        expect(model_class.mobility_backend_class("title")).to be < backend_class1
        expect(model_class.mobility_backend_class("content")).to be < backend_class1
        expect(model_class.mobility_backend_class("subtitle")).to be < backend_class2
      end

      it "handles new backends added after first called" do
        backend_class1 = Class.new
        backend_class1.include(Mobility::Backend)

        mod = attributes_class.new("title", backend: :null)
        model_class.include mod

        expect(model_class.mobility_backend_class("title")).to eq(mod.backend_class)

        other_mod = attributes_class.new("content", backend: :null)
        model_class.include other_mod

        expect(model_class.mobility_backend_class("content")).to eq(other_mod.backend_class)
      end
    end

    describe "#mobility_backends" do
      it "returns instance of backend for attribute" do
        mod1 = attributes_class.new("title", backend: :null)
        mod2 = attributes_class.new("content", backend: :null, foo: :bar)
        model_class.include mod1
        model_class.include mod2
        instance1 = model_class.new
        instance2 = model_class.new

        aggregate_failures do
          expect(instance1.mobility_backends).to eq({})
          expect(instance2.mobility_backends).to eq({})

          instance1.mobility_backends[:title] # trigger memoization

          expect(instance1.mobility_backends.keys).to eq([:title])
          expect(instance1.mobility_backends[:title].class).to eq(mod1.backend_class)
          expect(instance2.mobility_backends.size).to eq(0)

          instance2.mobility_backends[:content] # trigger memoization

          expect(instance1.mobility_backends.keys).to eq([:title])
          expect(instance1.mobility_backends[:title].class).to eq(mod1.backend_class)
          expect(instance2.mobility_backends.keys).to eq([:content])
          expect(instance2.mobility_backends[:content].class).to eq(mod2.backend_class)
        end
      end

      it "maps string keys to symbol key values" do
        mod = attributes_class.new("title", backend: :null)
        model_class.include mod

        article = model_class.new

        aggregate_failures do
          expect(article.mobility_backends[:title]).to be_a(Mobility::Backends::Null)
          expect(article.mobility_backends["title"]).to be_a(Mobility::Backends::Null)
          expect(article.mobility_backends.size).to eq(1)
          expect(article.mobility_backends[:title]).to eq(article.mobility_backends["title"])
        end
      end

      it "resets when model is duplicated" do
        mod = attributes_class.new("title", backend: :null)
        model_class.include mod

        article = model_class.new
        article.mobility_backends[:title] # trigger memoization
        other = article.dup

        expect(other.title_backend).not_to eq(article.title_backend)
      end
    end
  end

  describe "defining attribute backend on model" do
    before { model_class.include attributes_class.new("title", backend: backend_class, foo: "bar") }

    it "defines <attribute_name>_backend method which returns backend instance" do
      expect(backend_class).to receive(:new).once.with(instance, "title").and_call_original
      expect(instance.mobility_backends[:title]).to be_a(backend_class)
    end

    it "memoizes backend instance" do
      expect(backend_class).to receive(:new).once.with(instance, "title").and_call_original
      2.times { instance.mobility_backends[:title] }
    end
  end

  describe "#backend_name" do
    it "returns backend name" do
      attributes = attributes_class.new("title", "content", backend: :null)
      expect(attributes.backend_name).to eq(:null)
    end
  end

  describe "#inspect" do
    it "includes backend name and attribute names" do
      attributes = attributes_class.new("title", "content", backend: :null)
      expect(attributes.inspect).to eq("#<Attributes (null) @names=title, content>")
    end
  end
end
