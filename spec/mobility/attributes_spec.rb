require "spec_helper"

describe Mobility::Attributes do
  before do
    stub_const 'Article', Class.new
    Article.include Mobility
  end

  # In order to be able to stub methods on backend instance methods, which will be
  # hidden when the backend class is subclassed in Attributes, we inject a double
  # and delegate read and write to the double. (Nice trick, eh?)
  #
  let(:backend) { double("backend", read: nil, write: nil) }
  let(:backend_klass) do
    backend_double = backend
    Class.new(Mobility::Backend::Null) do
      define_method :read do |*args|
        backend_double.read(*args)
      end

      define_method :write do |*args|
        backend_double.write(*args)
      end
    end
  end

  describe "initializing" do
    it "raises ArgumentError if method is not reader, writer or accessor" do
      expect { described_class.new(:foo) }.to raise_error(ArgumentError)
    end

    it "raises BackendRequired error if backend is nil and no default is set" do
      expect { described_class.new(:accessor, "title") }.to raise_error(Mobility::BackendRequired)
    end

    it "does not raise error if backend is nil but default_backend is set" do
      original_default_backend = Mobility.config.default_backend
      Mobility.config.default_backend = :null
      expect { described_class.new(:accessor, "title") }.not_to raise_error
      Mobility.config.default_backend = original_default_backend
    end
  end

  describe "including Attributes in a model" do
    it "calls configure! on backend class with options" do
      expect(backend_klass).to receive(:configure!).with({ foo: "bar" })
      Article.include described_class.new(:accessor, "title", { backend: backend_klass, foo: "bar" })
    end

    it "calls setup_model on backend class with model_class, attributes, and options" do
      expect(backend_klass).to receive(:setup_model).with(Article, ["title"], {})
      Article.include described_class.new(:accessor, "title", { backend: backend_klass })
    end

    it "includes module in model_class.mobility" do
      backend_module = described_class.new(:accessor, "title", { backend: backend_klass })
      Article.include backend_module
      expect(Article.mobility.modules).to eq([backend_module])
    end

    describe "cache" do
      it "includes Backend::Cache into backend when options[:cache] is not false" do
        expect(backend_klass).to receive(:include).with(Mobility::Backend::Cache)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, fallbacks: false })
      end

      it "does not include Backend::Cache into backend when options[:cache] is false" do
        expect(backend_klass).not_to receive(:include).with(Mobility::Backend::Cache)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false, fallbacks: false })
      end
    end

    describe "dirty" do
      context "ActiveModel", orm: :active_record do
        it "includes Backend::ActiveModel::Dirty into backend when options[:dirty] is truthy and model class includes ActiveModel::Dirty" do
          expect(backend_klass).to receive(:include).with(Mobility::Backend::ActiveModel::Dirty)
          Article.include ::ActiveModel::Dirty
          Article.include described_class.new(:accessor, "title", {
            backend: backend_klass,
            cache: false,
            fallbacks: false,
            dirty: true,
            model_class: Article
          })
        end

        it "does not include Backend::Model::Dirty into backend when options[:dirty] is falsey" do
          expect(backend_klass).not_to receive(:include).with(Mobility::Backend::ActiveModel::Dirty)
          Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false, fallbacks: false, model_class: Article })
        end
      end

      context "Sequel", orm: :sequel do
        before do
          stub_const 'Article', Class.new(::Sequel::Model)
          Article.include Mobility
        end

        it "includes Backend::Sequel::Dirty into backend when options[:dirty] is truthy and model class is a ::Sequel::Model" do
          expect(backend_klass).to receive(:include).with(Mobility::Backend::Sequel::Dirty)
          Article.include described_class.new(:accessor, "title", {
            backend: backend_klass,
            cache: false,
            fallbacks: false,
            dirty: true,
            model_class: Article
          })
        end

        it "does not include Backend::Sequel::Dirty into backend when options[:dirty] is falsey" do
          expect(backend_klass).not_to receive(:include).with(Mobility::Backend::Sequel::Dirty)
          Article.include described_class.new(:accessor, "title", {
            backend: backend_klass,
            cache: false,
            fallbacks: false,
            model_class: Article
          })
        end
      end
    end

    describe "fallbacks" do
      it "includes Backend::Fallbacks into backend when options[:fallbacks] is not false" do
        expect(backend_klass).to receive(:include).with(Mobility::Backend::Fallbacks)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false })
      end

      it "does not include Backend::Fallbacks into backend when options[:fallbacks] is false" do
        expect(backend_klass).not_to receive(:include).with(Mobility::Backend::Fallbacks)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false, fallbacks: false })
      end
    end

    describe "defining attribute backend on model" do
      before do
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, foo: "bar" })
      end
      let(:article) { Article.new }

      it "defines <attribute_name>_backend method which returns backend instance" do
        expect(backend_klass).to receive(:new).once.with(article, "title", { foo: "bar" }).and_call_original
        expect(article.mobility_backend_for("title")).to be_a(Mobility::Backend::Null)
      end

      it "memoizes backend instance" do
        expect(backend_klass).to receive(:new).once.with(article, "title", { foo: "bar" }).and_call_original
        2.times { article.mobility_backend_for("title") }
      end
    end

    describe "defining getters and setters" do
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

        it "correctly maps locale through getter options" do
          expect(backend).to receive(:read).with(:fr, {}).and_return("foo")
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
      end

      describe "method = :accessor" do
        before { Article.include described_class.new(:accessor, "title", { backend: backend_klass }) }

        it_behaves_like "reader"
        it_behaves_like "writer"
      end

      describe "method = :reader" do
        before { Article.include described_class.new(:reader, "title", { backend: backend_klass }) }

        it_behaves_like "reader"

        it "does not define writer" do
          expect { article.title = "foo" }.to raise_error(NoMethodError)
        end
      end

      describe "method = :writer" do
        before { Article.include described_class.new(:writer, "title", { backend: backend_klass }) }

        it_behaves_like "writer"

        it "does not define reader" do
          expect { article.title }.to raise_error(NoMethodError)
        end
      end

      # Note: this is important normalization so backends do not need
      # to consider storing blank values.
      it "converts blanks to nil when receiving from backend getter" do
        Article.include described_class.new(:reader, "title", { backend: backend_klass })
        allow(Mobility).to receive(:locale).and_return(:cz)
        expect(backend).to receive(:read).with(:cz, {}).and_return("")
        expect(article.title).to eq(nil)
      end

      it "converts blanks to nil when sending to backend setter" do
        Article.include described_class.new(:writer, "title", { backend: backend_klass })
        allow(Mobility).to receive(:locale).and_return(:fr)
        expect(backend).to receive(:write).with(:fr, nil, {})
        article.title = ""
      end

      it "does not convert false values to nil when receiving from backend getter" do
        Article.include described_class.new(:reader, "title", { backend: backend_klass })
        allow(Mobility).to receive(:locale).and_return(:cz)
        expect(backend).to receive(:read).with(:cz, {}).and_return(false)
        expect(article.title).to eq(false)
      end

      it "does not convert false values to nil when sending to backend setter" do
        Article.include described_class.new(:writer, "title", { backend: backend_klass })
        allow(Mobility).to receive(:locale).and_return(:fr)
        expect(backend).to receive(:write).with(:fr, false, {})
        article.title = false
      end
    end

    describe "defining locale accessors" do
      let(:article) { Article.new }
      before do
        Article.include described_class.new(:accessor, "title", options.merge(backend: backend_klass))
      end

      context "with locale_accessors unset" do
        let(:options) { {} }

        it "does not define locale accessors" do
          expect { article.title_en }.to raise_error(NoMethodError)
          expect { article.title_en? }.to raise_error(NoMethodError)
          expect { article.title_de }.to raise_error(NoMethodError)
          expect { article.title_de? }.to raise_error(NoMethodError)
        end
      end

      context "with locale_accessors = true" do
        let(:options) { { locale_accessors: true, cache: false } }

        it "defines accessors for locales in I18n.available_locales" do
          expect(backend).to receive(:read).twice.with(:de, {}).and_return("foo")
          expect(article.title_de).to eq("foo")
          expect(article.title_de?).to eq(true)
          expect(backend).to receive(:read).with(:de, {}).and_return("")
          expect(article.title_de?).to eq(false)
          expect(backend).to receive(:read).with(:de, {}).and_return(nil)
          expect(article.title_de?).to eq(false)
        end

        it "does not define accessors for other locales" do
          expect { article.title_pt }.to raise_error(NoMethodError)
          expect { article.title_pt? }.to raise_error(NoMethodError)
        end
      end

      context "with locale_accessors a hash" do
        let(:options) { { locale_accessors: [:en, :'pt-BR'], cache: false } }

        it "defines accessors for locales in locale_accessors hash" do
          expect(backend).to receive(:read).twice.with(:en, {}).and_return("enfoo")
          expect(article.title_en).to eq("enfoo")
          expect(article.title_en?).to eq(true)
          expect(backend).to receive(:read).twice.with(:'pt-BR', {}).and_return("ptfoo")
          expect(article.title_pt_br).to eq("ptfoo")
          expect(article.title_pt_br?).to eq(true)
        end

        it "does not define accessors for locales not in locale_accessors hash" do
          expect { article.title_de }.to raise_error(NoMethodError)
          expect { article.title_de? }.to raise_error(NoMethodError)
          expect { article.title_es }.to raise_error(NoMethodError)
          expect { article.title_es? }.to raise_error(NoMethodError)
        end
      end

      context "accessor locale includes dash" do
        let(:options) { { locale_accessors: [:'pt-BR'], cache: false } }

        it "translates dashes to underscores when defining locale accessors" do
          expect(backend).to receive(:read).with(:'pt-BR', {}).twice.and_return("foo")
          expect(article.title_pt_br).to eq("foo")
          expect(article.title_pt_br?).to eq(true)
        end
      end
    end

    describe "fallthrough accessors" do
      let(:article) { Article.new }
      before do
        Article.include described_class.new(:accessor, "title", options.merge(backend: backend_klass))
      end

      context "with fallthrough_accessors = true" do
        let(:options) { { fallthrough_accessors: true, cache: false } }

        it "handle getters for any locale" do
          expect(backend).to receive(:read).with(:de, {}).and_return("foo")
          expect(article.title_de).to eq("foo")
          expect(backend).to receive(:read).with(:fr, {}).and_return("bar")
          expect(article.title_fr).to eq("bar")
        end

        it "handle setters for any locale" do
          expect(backend).to receive(:write).with(:de, "foo", {}).and_return("foo")
          expect(article.title_de="foo").to eq("foo")
          expect(backend).to receive(:write).with(:fr, "bar", {}).and_return("bar")
          expect(article.title_fr="bar").to eq("bar")
        end

        it "handles presence methods for any locale" do
          expect(backend).to receive(:read).with(:de, {}).and_return("foo")
          expect(article.title_de?).to eq(true)
          expect(backend).to receive(:read).with(:de, {}).and_return("")
          expect(article.title_de?).to eq(false)
          expect(backend).to receive(:read).with(:de, {}).and_return(nil)
          expect(article.title_de?).to eq(false)
        end
      end
    end
  end

  describe "#each" do
    it "delegates to attributes" do
      attributes = described_class.new(:accessor, :title, :content, backend: :null)
      expect { |b| attributes.each(&b) }.to yield_successive_args("title", "content")
    end
  end

  describe "#backend_name" do
    it "returns backend name" do
      attributes = described_class.new(:accessor, :title, :content, backend: :null)
      expect(attributes.backend_name).to eq(:null)
    end
  end
end
