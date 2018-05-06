require "spec_helper"

describe Mobility::Attributes do
  before do
    stub_const 'Article', Class.new
    Article.extend Mobility
  end

  # In order to be able to stub methods on backend instance methods, which will be
  # hidden when the backend class is subclassed in Attributes, we inject a double
  # and delegate read and write to the double. (Nice trick, eh?)
  #
  let(:backend) { double("backend") }
  let(:backend_class) do
    backend_double = backend
    Class.new(Mobility::Backends::Null) do
      define_method :read do |*args|
        backend_double.read(*args)
      end

      define_method :write do |*args|
        backend_double.write(*args)
      end
    end
  end

  # These options disable all inclusion of modules into backend, which is useful
  # for many specs in this suite.
  let(:clean_options) { { cache: false, fallbacks: false, presence: false } }

  describe "initializing" do
    it "raises ArgumentError if method is not reader, writer or accessor" do
      expect { described_class.new(method: :foo) }.to raise_error(ArgumentError)
    end

    it "raises BackendRequired error if backend is nil and no default is set" do
      expect { described_class.new("title") }.to raise_error(Mobility::BackendRequired)
    end

    it "does not raise error if backend is nil but default_backend is set" do
      original_default_backend = Mobility.config.default_backend
      Mobility.config.default_backend = :null
      expect { described_class.new("title") }.not_to raise_error
      Mobility.config.default_backend = original_default_backend
    end
  end

  describe "including Attributes in a model" do
    let(:expected_options) { { foo: "bar", **Mobility.default_options, model_class: Article } }

    it "calls build_subclass on backend class with options merged with default options" do
      expect(backend_class).to receive(:build_subclass).with(expected_options).and_return(Class.new(backend_class))
      attributes = described_class.new("title", backend: backend_class, foo: "bar")
      Article.include attributes
    end

    it "assigns options to backend class" do
      attributes = described_class.new("title", backend: backend_class, foo: "bar")
      Article.include attributes
      expect(attributes.options).to eq(attributes.backend_class.options)
      expect(attributes.backend_class.options).to eq(Mobility.default_options.merge(model_class: Article, foo: "bar"))
    end

    it "freezes options after inclusion into model class" do
      attributes = described_class.new("title", backend: backend_class)
      Article.include attributes
      expect(attributes.options).to be_frozen
    end

    it "calls setup_model on backend class with model_class and attributes" do
      expect(backend_class).to receive(:setup_model).with(Article, ["title"])
      Article.include described_class.new("title", backend: backend_class)
    end

    it "includes module in model_class.mobility" do
      attributes = described_class.new("title", backend: backend_class)
      Article.include attributes
      expect(Article.mobility.modules).to eq([attributes])
    end

    describe "cache" do
      it "includes Plugins::Cache into backend when options[:cache] is not false" do
        clean_options.delete(:cache)
        attributes = described_class.new("title", backend: backend_class, **clean_options)
        Article.include attributes
        expect(attributes.backend_class.ancestors).to include(Mobility::Plugins::Cache)
      end

      it "does not include Plugins::Cache into backend when options[:cache] is false" do
        attributes = described_class.new("title", backend: backend_class, **clean_options)
        Article.include attributes
        expect(attributes.backend_class.ancestors).not_to include(Mobility::Plugins::Cache)
      end
    end

    describe "defining attribute backend on model" do
      before do
        Article.include described_class.new("title", backend: backend_class, foo: "bar")
      end
      let(:article) { Article.new }
      let(:expected_options) { { foo: "bar", **Mobility.default_options, model_class: Article } }

      it "defines <attribute_name>_backend method which returns backend instance" do
        expect(backend_class).to receive(:new).once.with(article, "title").and_call_original
        expect(article.mobility.backend_for("title")).to be_a(Mobility::Backends::Null)
      end

      it "memoizes backend instance" do
        expect(backend_class).to receive(:new).once.with(article, "title").and_call_original
        2.times { article.mobility.backend_for("title") }
      end
    end

    describe "defining getters and setters" do
      let(:model) { double("model") }
      before do
        model_double = model
        mod = Module.new do
          define_method :title do
            model_double.title
          end

          define_method :title? do
            model_double.title?
          end

          define_method :title= do |value|
            model_double.title = value
          end
        end
        Article.include mod
      end
      let(:article) { Article.new }

      shared_examples_for "reader" do
        it "correctly maps getter method for translated attribute to backend" do
          expect(Mobility).to receive(:locale).and_return(:de)
          expect(backend).to receive(:read).with(:de, {}).and_return("foo")
          expect(article.title).to eq("foo")
        end

        it "correctly maps presence method for translated attribute to backend" do
          expect(Mobility).to receive(:locale).and_return(:de)
          expect(backend).to receive(:read).with(:de, {}).and_return("foo")
          expect(article.title?).to eq(true)
        end

        it "correctly maps locale through getter options and converts to boolean" do
          expect(backend).to receive(:read).with(:fr, locale: true).and_return("foo")
          expect(article.title(locale: "fr")).to eq("foo")
        end

        it "raises InvalidLocale exception if locale is not in I18n.available_locales" do
          expect { article.title(locale: :it) }.to raise_error(Mobility::InvalidLocale)
        end

        it "correctly maps other options to getter" do
          expect(Mobility).to receive(:locale).and_return(:de)
          expect(backend).to receive(:read).with(:de, someopt: "someval").and_return("foo")
          expect(article.title(someopt: "someval")).to eq("foo")
        end

        it "calls original getter when super: true passed as option" do
          expect(model).to receive("title").and_return("foo")
          expect(article.title(super: true)).to eq("foo")
        end

        it "calls original presence method when super: true passed as option" do
          expect(model).to receive("title?").and_return(true)
          expect(article.title?(super: true)).to eq(true)
        end
      end

      shared_examples_for "writer" do
        it "correctly maps setter method for translated attribute to backend" do
          expect(Mobility).to receive(:locale).and_return(:de)
          expect(backend).to receive(:write).with(:de, "foo", {})
          article.title = "foo"
        end

        it "correctly maps other options to setter" do
          expect(Mobility).to receive(:locale).and_return(:de)
          expect(backend).to receive(:write).with(:de, "foo", someopt: "someval").and_return("foo")
          expect(article.send(:title=, "foo", someopt: "someval")).to eq("foo")
        end

        it "calls original setter when super: true passed as option" do
          expect(model).to receive("title=").with("foo")
          article.send(:title=, "foo", super: true)
        end
      end

      describe "method = :accessor" do
        before { Article.include described_class.new("title", backend: backend_class) }

        it_behaves_like "reader"
        it_behaves_like "writer"
      end

      describe "method = :reader" do
        before { Article.include described_class.new("title", backend: backend_class, method: :reader) }

        it_behaves_like "reader"

        it "calls original method" do
          expect(model).to receive(:title=).once.with("foo")
          article.title = "foo"
        end
      end

      describe "method = :writer" do
        before { Article.include described_class.new("title", backend: backend_class, method: :writer) }

        it_behaves_like "writer"

        it "does not define reader" do
          expect(model).to receive(:title).once.and_return("model foo")
          expect(article.title).to eq("model foo")
        end
      end

      # Note: this is important normalization so backends do not need
      # to consider storing blank values.
      it "converts blanks to nil when receiving from backend getter" do
        Article.include described_class.new(:reader, "title", backend: backend_class)
        allow(Mobility).to receive(:locale).and_return(:cz)
        expect(backend).to receive(:read).with(:cz, {}).and_return("")
        expect(article.title).to eq(nil)
      end

      it "converts blanks to nil when sending to backend setter" do
        Article.include described_class.new(:writer, "title", backend: backend_class)
        allow(Mobility).to receive(:locale).and_return(:fr)
        expect(backend).to receive(:write).with(:fr, nil, {})
        article.title = ""
      end

      it "does not convert false values to nil when receiving from backend getter" do
        Article.include described_class.new(:reader, "title", backend: backend_class)
        allow(Mobility).to receive(:locale).and_return(:cz)
        expect(backend).to receive(:read).with(:cz, {}).and_return(false)
        expect(article.title).to eq(false)
      end

      it "does not convert false values to nil when sending to backend setter" do
        Article.include described_class.new(:writer, "title", backend: backend_class)
        allow(Mobility).to receive(:locale).and_return(:fr)
        expect(backend).to receive(:write).with(:fr, false, {})
        article.title = false
      end
    end
  end

  describe "#each" do
    it "delegates to attributes" do
      attributes = described_class.new("title", "content", backend: :null)
      expect { |b| attributes.each(&b) }.to yield_successive_args("title", "content")
    end
  end

  describe "#backend_name" do
    it "returns backend name" do
      attributes = described_class.new("title", "content", backend: :null)
      expect(attributes.backend_name).to eq(:null)
    end
  end

  describe "#inspect" do
    it "returns backend name and attribute names" do
      attributes = described_class.new("title", "content", backend: :null)
      expect(attributes.inspect).to eq("#<Attributes (null) @names=title, content>")
    end
  end
end
