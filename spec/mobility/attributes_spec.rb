require "spec_helper"

describe Mobility::Attributes do
  before do
    stub_const 'Article', Class.new
    Article.include Mobility
  end

  let(:backend_klass) { Mobility::Backend::Null }

  describe "initializing" do
    it "raises ArgumentError if method is not reader, writer or accessor" do
      expect { described_class.new(:foo) }.to raise_error(ArgumentError)
    end

    it "raises BackendRequired error if backend is nil and no default is set" do
      expect { described_class.new(:accessor, "title") }.to raise_error(Mobility::BackendRequired)
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

    describe "cache" do
      it "includes Backend::Cache into backend when options[:cache] is not false" do
        expect(backend_klass).to receive(:include).with(Mobility::Backend::Cache)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass })
      end

      it "does not include Backend::Cache into backend when options[:cache] is false" do
        expect(backend_klass).not_to receive(:include).with(Mobility::Backend::Cache)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false })
      end
    end

    describe "dirty" do
      it "includes Backend::Dirty into backend when options[:dirty] is truty" do
        expect(backend_klass).to receive(:include).with(Mobility::Backend::Dirty)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false, dirty: true })
      end

      it "does not include Backend::Dirty into backend when options[:dirty] is falsey" do
        expect(backend_klass).not_to receive(:include).with(Mobility::Backend::Dirty)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false })
      end
    end

    describe "fallbacks" do
      it "includes Backend::Fallbacks into backend when options[:fallbacks] is truthy" do
        expect(backend_klass).to receive(:include).with(Mobility::Backend::Fallbacks)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, fallbacks: true, cache: false })
      end

      it "does not include Backend::Fallbacks into backend when options[:fallbacks] is falsey" do
        expect(backend_klass).not_to receive(:include).with(Mobility::Backend::Fallbacks)
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, cache: false })
      end
    end

    describe "defining attribute backend on model" do
      before do
        Article.include described_class.new(:accessor, "title", { backend: backend_klass, foo: "bar" })
      end
      let(:article) { Article.new }

      it "defines <attribute_name>_backend method which returns backend instance" do
        expect(backend_klass).to receive(:new).once.with(article, "title", { foo: "bar" }).and_call_original
        expect(article.title_translations).to be_a(Mobility::Backend::Null)
      end

      it "memoizes backend instance" do
        expect(backend_klass).to receive(:new).once.with(article, "title", { foo: "bar" }).and_call_original
        2.times { article.title_translations }
      end
    end

    describe "defining getters and setters" do
      let(:article) { Article.new }
      let(:backend) { backend_klass.new(article, "title", {}) }
      before do
        allow(backend_klass).to receive(:new).with(article, "title", {}).and_return(backend)
        allow(Mobility).to receive(:locale).and_return(:de)
      end

      shared_examples_for "reader" do
        it "correctly maps getter method for translated attribute to backend" do
          expect(backend).to receive(:read).with(:de).and_return("foo")
          expect(article.title).to eq("foo")
        end
      end

      shared_examples_for "writer" do
        it "correctly maps setter method for translated attribute to backend" do
          expect(backend).to receive(:write).with(:de, "foo")
          article.title = "foo"
        end
      end

      describe "method = :accessor" do
        before { Article.include described_class.new(:accessor, "title", { "backend" => backend_klass }) }

        it_behaves_like "reader"
        it_behaves_like "writer"
      end

      describe "method = :reader" do
        before { Article.include described_class.new(:reader, "title", { "backend" => backend_klass }) }

        it_behaves_like "reader"

        it "does not define writer" do
          expect { article.title = "foo" }.to raise_error(NoMethodError)
        end
      end

      describe "method = :writer" do
        before { Article.include described_class.new(:writer, "title", { "backend" => backend_klass }) }

        it_behaves_like "writer"

        it "does not define reader" do
          expect { article.title }.to raise_error(NoMethodError)
        end
      end

      # Note: this is important normalization so backends do not need
      # to consider storing blank values.
      it "converts blanks to nil when receiving from backend getter" do
        Article.include described_class.new(:reader, "title", { "backend" => backend_klass })
        allow(Mobility).to receive(:locale).and_return(:ru)
        expect(backend).to receive(:read).with(:ru).and_return("")
        expect(article.title).to eq(nil)
      end

      it "converts blanks to nil when sending to backend setter" do
        Article.include described_class.new(:writer, "title", { "backend" => backend_klass })
        allow(Mobility).to receive(:locale).and_return(:fr)
        expect(backend).to receive(:write).with(:fr, nil)
        article.title = ""
      end
    end

    describe "defining locale accessors" do
      let(:article) { Article.new }
      let(:backend) { backend_klass.new(article, "title", options) }
      before do
        allow(backend_klass).to receive(:new).with(article, "title", options).and_return(backend)
        allow(Mobility).to receive(:locale).and_return(:de)
        Article.include described_class.new(:accessor, "title", options.merge("backend" => backend_klass))
      end

      context "with accessor_locales unset" do
        let(:options) { {} }

        it "does not define locale accessors" do
          expect { article.title_en }.to raise_error(NoMethodError)
          expect { article.title_de }.to raise_error(NoMethodError)
        end
      end

      context "with accessor_locales = true" do
        let(:options) { { locale_accessors: true } }

        it "defines accessors for locales in I18n.available_locales" do
          expect(backend).to receive(:read).with(:de).and_return("foo")
          expect(article.title_de).to eq("foo")
        end

        it "does not define accessors for other locales" do
          expect { article.title_pt }.to raise_error(NoMethodError)
        end
      end

      context "with accessor_locales a hash" do
        let(:options) { { locale_accessors: [:en, :pt] } }

        it "defines accessors for locales in locale_accessors hash" do
          expect(backend).to receive(:read).with(:en).and_return("enfoo")
          expect(article.title_en).to eq("enfoo")
          expect(backend).to receive(:read).with(:pt).and_return("ptfoo")
          expect(article.title_pt).to eq("ptfoo")
        end

        it "does not define accessors for locales not in locale_accessors hash" do
          expect { article.title_de }.to raise_error(NoMethodError)
          expect { article.title_es }.to raise_error(NoMethodError)
        end
      end

      context "accessor locale includes dash" do
        let(:options) { { locale_accessors: [:'pt-BR'] } }

        it "translates dashes to underscores when defining locale accessors" do
          expect(backend).to receive(:read).with(:'pt-BR').and_return("foo")
          expect(article.title_pt_br).to eq("foo")
        end
      end

      context "with backend that uses a stash" do
        let(:options) { { locale_accessors: true } }

        it "returns value from stash" do
          stash = double("stash")
          expect(article.title_en).to eq(nil)
          expect(stash).to receive(:to_s).once.and_return("foo")
          expect(backend).to receive(:read).with(:en).and_return(stash)
          expect(article.title_en).to eq("foo")
        end
      end
    end
  end
end
