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
  end
end
