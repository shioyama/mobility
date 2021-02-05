require "spec_helper"
require "mobility/plugins/backend"
require "mobility/plugins/writer"
require "mobility/backends/null"

describe Mobility::Plugins::Backend, type: :plugin do
  plugins :backend
  plugin_setup

  define_plugins :foo

  # Override default helper-defined model_class which has attributes module
  # pre-included, so we can explicitly include it in specs.
  let(:model_class) { Class.new }
  before do
    # Define 'foo' as a valid option key for this backend
    allow(backend_class).to receive(:valid_keys).and_return([:foo])
  end

  describe "#included" do
    it "calls build_subclass on backend class with options merged with default options" do
      expect(backend_class).to receive(:build_subclass).with(model_class, hash_including(foo: "bar")).and_return(Class.new(backend_class))
      translations = translations_class.new("title", backend: backend_class, foo: "bar")
      model_class.include translations
    end

    it "assigns options to backend class" do
      translations = translations_class.new("title", backend: backend_class, foo: "bar")
      model_class.include translations
      expect(translations.backend_class.options).to eq(backend: backend_class, foo: "bar")
    end

    it "freezes backend options after inclusion into model class" do
      translations = translations_class.new("title", backend: backend_class)
      model_class.include translations
      expect(backend_class.options).to be_frozen
    end

    it "calls setup_model on backend class with model_class and attributes" do
      expect(backend_class).to receive(:setup_model).with(model_class, ["title"])
      model_class.include translations_class.new("title", backend: backend_class)
    end

    describe ".mobility_backend_class" do
      it "returns backend class for attribute" do
        backend_class1 = Class.new
        backend_class1.include(Mobility::Backend)
        backend_class2 = Class.new
        backend_class2.include(Mobility::Backend)

        mod1 = translations_class.new("title", "content", backend: backend_class1)
        mod2 = translations_class.new("subtitle", backend: backend_class2)

        model_class.include mod1
        model_class.include mod2

        expect(model_class.mobility_backend_class("title")).to be < backend_class1
        expect(model_class.mobility_backend_class("content")).to be < backend_class1
        expect(model_class.mobility_backend_class("subtitle")).to be < backend_class2
      end

      it "handles new backends added after first called" do
        backend_class1 = Class.new
        backend_class1.include(Mobility::Backend)

        mod = translations_class.new("title", backend: :null)
        model_class.include mod

        expect(model_class.mobility_backend_class("title")).to eq(mod.backend_class)

        other_mod = translations_class.new("content", backend: :null)
        model_class.include other_mod

        expect(model_class.mobility_backend_class("content")).to eq(other_mod.backend_class)
      end

      it "works with subclasses" do
        backend_class_1 = Class.new
        backend_class_1.include Mobility::Backend

        mod1 = translations_class.new("title", backend: backend_class_1)
        model_class.include mod1

        backend_class_2 = Class.new
        backend_class_2.include Mobility::Backend

        model_subclass = Class.new(model_class)
        mod2 = translations_class.new("content", backend: backend_class_2)

        model_subclass.include mod2

        title_backend_class_1 = model_class.mobility_backend_class("title")
        title_backend_class_2 = model_subclass.mobility_backend_class("title")

        expect(title_backend_class_1).to be <(backend_class_1)
        expect(title_backend_class_2).to be <(backend_class_1)

        expect {
          model_class.mobility_backend_class("content")
        }.to raise_error(KeyError, "No backend for: content")
        content_backend_class = model_subclass.mobility_backend_class("content")
        expect(content_backend_class).to be <(backend_class_2)
      end

      it "freezes backends after subclassing" do
        backend_class_1 = Class.new
        backend_class_1.include Mobility::Backend

        mod1 = translations_class.new("title", backend: backend_class_1)
        model_class.include mod1

        Class.new(model_class)

        expect(model_class.send(:mobility_backend_classes)).to be_frozen
      end
    end

    describe "#mobility_backends" do
      it "returns instance of backend for attribute" do
        mod1 = translations_class.new("title", backend: :null)
        mod2 = translations_class.new("content", backend: :null)
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
        mod = translations_class.new("title", backend: :null)
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
        mod = translations_class.new("title", backend: :null)
        model_class.include mod

        article = model_class.new
        article.mobility_backends[:title] # trigger memoization
        other = article.dup

        expect(other.mobility_backends[:title]).not_to eq(article.mobility_backends[:title])
      end

      # regression test for https://github.com/shioyama/mobility/issues/494
      it "does not prevent Marshal.dump from working" do
        mod = translations_class.new("title", backend: :null)
        stub_const('Article', model_class)
        model_class.include mod

        article = model_class.new
        article.mobility_backends[:title]
        expect {
          expect(Marshal.dump(article)).not_to be_nil
        }.not_to raise_error
      end
    end
  end

  describe "#initialize" do
    define_plugins :my_plugin

    let(:pluggable) do
      Class.new(Mobility::Pluggable) do |pluggable|
        pluggable.plugin :my_plugin
      end
    end

    before do
      Mobility::Backends.register_backend(:my_backend, backend_class)

      stub_const('OtherBackendClass', Class.new)
      Mobility::Backends.register_backend(:other_backend, OtherBackendClass)
      def OtherBackendClass.valid_keys
        [:bar]
      end
    end

    after do
      backends = Mobility::Backends.instance_variable_get(:@backends)
      backends.delete(:my_backend)
      backends.delete(:other_backend)
    end

    it "excludes backend options from plugin key validation" do
      pluggable.plugin :backend, :my_backend

      translations = pluggable.new(my_plugin: 'my_plugin', foo: 'bar')
      expect(translations.options).to eq(backend: [:my_backend, {}], foo: 'bar', my_plugin: 'my_plugin')
      expect(translations.backend_options).to eq(backend: [:my_backend, {}], foo: 'bar', my_plugin: 'my_plugin')

      expect {
        pluggable.new(my_plugin: 'my_plugin', other: 'other')
      }.to raise_error(Mobility::Pluggable::InvalidOptionKey, "No plugin configured for these keys: other.")
    end

    it "validates backend options when backend is an array" do
      pluggable.plugin :backend, :my_backend, foo: "foo"

      translations = pluggable.new(my_plugin: 'my_plugin', backend: [:other_backend, bar: "bar"])
      expect(translations.options).to eq(backend: [:other_backend, bar: 'bar'], my_plugin: 'my_plugin')
      expect(translations.backend_options).to eq(backend: [:other_backend, bar: 'bar'], bar: 'bar', my_plugin: 'my_plugin')
      expect(translations.options).not_to be(translations.backend_options)

      expect {
        pluggable.new(my_plugin: 'my_plugin', backend: [:other_backend, baz: "baz"])
      }.to raise_error(Mobility::Plugins::Backend::InvalidOptionKey, "These are not valid other_backend backend keys: baz.")
      expect {
        pluggable.new(my_plugin: 'my_plugin', backend: :other_backend, foo: "foo")
      }.to raise_error(Mobility::Pluggable::InvalidOptionKey, "No plugin configured for these keys: foo.")
    end

    it "validates correct mixed in backend options" do
      pluggable.plugin :backend, backend_class, foo: "foo"

      translations = pluggable.new(backend: :other_backend, bar: "bar")
      expect(translations.options).to eq(backend: :other_backend, bar: 'bar')
      expect(translations.backend_options).to eq(backend: :other_backend, bar: 'bar')
      expect(translations.options).not_to be(translations.backend_options)
    end
  end

  describe "defining attribute backend on model" do
    before { model_class.include translations_class.new("title", backend: backend_class, foo: "bar") }

    it "defines <attribute_name>_backend method which returns backend instance" do
      expect(backend_class).to receive(:new).once.with(instance, "title").and_call_original
      expect(instance.mobility_backends[:title]).to be_a(backend_class)
    end

    it "memoizes backend instance" do
      expect(backend_class).to receive(:new).once.with(instance, "title").and_call_original
      2.times { instance.mobility_backends[:title] }
    end
  end

  describe "#backend" do
    it "returns backend superclass" do
      translations = translations_class.new("title", "content", backend: :null)
      expect(translations.backend).to eq(Mobility::Backends::Null)
    end
  end

  describe "#inspect" do
    it "includes backend name and attribute names" do
      translations = translations_class.new("title", "content", backend: :null)
      expect(translations.inspect).to eq("#<Translations (Mobility::Backends::Null) @names=title, content>")
    end
  end

  describe "configuring defaults" do
    before do
      backend_class = stub_const("FooBackend", Class.new(Mobility::Backends::Null))
      expect(backend_class).to receive(:valid_keys).at_least(1).time.and_return([:association_name])
      Mobility::Backends.register_backend(:foo, FooBackend)
    end
    after { Mobility::Backends.instance_variable_get(:@backends).delete(:foo) }

    describe "default without backend options" do
      plugins do
        backend :foo
      end

      it "shows backend name in inspect string" do
        expect(translations_class.new("title").inspect).to eq("#<Translations (FooBackend) @names=title>")
      end

      it "calls setup_model on backend" do
        expect(FooBackend).to receive(:setup_model).with(model_class, ["title"])
        model_class.include translations_class.new("title")
      end
    end

    describe "default with invalid backend option" do
      plugins do
        backend :foo, invalid_option: :bar
      end

      it "raises exception when instantiated" do
        expect {
          translations_class.new("title")
        }.to raise_error(Mobility::Plugins::Backend::InvalidOptionKey,
                         "These are not valid foo backend keys: invalid_option.")
      end
    end

    describe "default with backend options" do
      plugins do
        backend :foo, association_name: :bar
      end

      it "assigns backend name correctly" do
        expect(translations_class.new("title").backend).to eq(FooBackend)
      end

      it "passes backend options to backend" do
        translations = translations_class.new("title")
        expect(FooBackend).to receive(:configure).with(hash_including(association_name: :bar))
        model_class.include(translations)
      end

      it "passes module options if backend_options passed explicitly to initializer" do
        translations = translations_class.new("title", backend: [:foo, { association_name: :baz }])
        expect(FooBackend).to receive(:configure).with(hash_including(association_name: :baz))
        model_class.include(translations)
      end

      it "passes module options if backend options passed implicitly to initializer" do
        translations = translations_class.new("title", backend: :foo, association_name: :baz)
        expect(FooBackend).to receive(:configure).with(hash_including(association_name: :baz))
        model_class.include(translations)
      end

      it "overrides backend option from options passed to initializer even when backend: key is missing" do
        translations = translations_class.new("title", association_name: :baz)
        expect(FooBackend).to receive(:configure).with(hash_including(association_name: :baz))
        model_class.include(translations)
      end

      it "does not override original backend options hash" do
        backend_options = { association_name: :foo }
        expect {
          translations = translations_class.new("title", backend: [:foo, backend_options])
          model_class.include(translations)
        }.not_to change { backend_options }
      end
    end
  end
end
