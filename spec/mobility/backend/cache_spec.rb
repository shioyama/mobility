require "spec_helper"

describe Mobility::Backend::Cache do
  let(:backend_class) do
    Class.new(Mobility::Backend::Null) do
      attr_reader :reads, :writes

      def initialize(*)
        @reads = @writes = 0
      end

      def read(*)
        @reads += 1
        nil
      end

      def write(locale, value, options = {})
        @writes += 1
        value
      end
    end
  end

  let(:cached_backend_class) do
    Class.new(backend_class).include(described_class)
  end

  let(:cached_backend_class_with_stash) do
    klass = Class.new(backend_class) do
      def read(*)
        @reads += 1
        nil
      end

      def write(locale, value, options = {})
        @writes += 1
        # let's implement a very simple stash
        value.instance_eval { alias :write :replace }
        value
      end
    end
    Class.new(klass).include(described_class)
  end

  context "non-ActiveRecord model" do
    let(:model_class) { Class.new }
    let(:model) { model_class.new }

    describe "caching reads" do
      it "retrieves value from backend every time with no cache" do
        backend = backend_class.new(model, "title")
        3.times { backend.read(:en) }
        expect(backend.reads).to eq(3)
        expect(backend.writes).to eq(0)
      end

      it "retrieves value from backend on first read only with cache" do
        backend = cached_backend_class.new(model, "title")
        3.times { backend.read(:en) }
        expect(backend.reads).to eq(1)
        expect(backend.writes).to eq(0)
      end
    end

    describe "updating on writes" do
      it "updates cache on write" do
        backend = cached_backend_class.new(model, "title")
        expect(backend.read(:en)).to eq(nil)
        expect(backend.write(:en, "foo")).to eq("foo")
        expect(backend.read(:en)).to eq("foo")
        expect(backend.write(:en, "bar")).to eq("bar")
        expect(backend.read(:en)).to eq("bar")
        expect(backend.reads).to eq(1)
        expect(backend.writes).to eq(2)
      end

      context "backend using values with setter" do
        it "updates cache on write with no request to backend" do
          backend = cached_backend_class_with_stash.new(model, "title")
          expect(backend.read(:en)).to eq(nil)
          expect(backend.write(:en, "foo")).to eq("foo")
          expect(backend.read(:en)).to eq("foo")
          expect(backend.write(:en, "bar")).to eq("bar")
          expect(backend.read(:en)).to eq("bar")
          expect(backend.reads).to eq(1)
          # only one write, since second time reads from stash
          expect(backend.writes).to eq(1)
        end
      end
    end

    describe "with two instances" do
      it "does not share cache between instances" do
        backend = cached_backend_class.new(model, "title")
        other_backend = cached_backend_class.new(model_class.new, "title")
        expect(backend.read(:en)).to eq(nil)
        expect(other_backend.read(:en)).to eq(nil)
        backend.write(:en, "foo")
        other_backend.write(:en, "bar")
        expect(backend.read(:en)).to eq("foo")
        expect(other_backend.read(:en)).to eq("bar")
      end
    end

    describe "#clear_cache" do
      it "clears cache" do
        backend = cached_backend_class.new(model, "title")
        expect(backend.read(:en)).to eq(nil)
        backend.write(:en, "foo")
        expect(backend.read(:en)).to eq("foo")
        backend.clear_cache
        expect(backend.read(:en)).to eq(nil)
      end
    end
  end

  context "ActiveRecord model" do
    before do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      Article.include Mobility
    end

    context "with one backend" do
      before do
        Article.translates :title, backend: backend_class, cache: true
        @article = Article.create
      end

      shared_examples_for "cache that resets on model action" do |action|
        it "updates backend cache on #{action}" do
          backend = @article.title_translations
          backend.write(:en, "foo")
          expect(backend.read(:en)).to eq("foo")
          @article.send action
          expect(backend.read(:en)).to eq(nil)
        end
      end

      it_behaves_like "cache that resets on model action", :reload
      it_behaves_like "cache that resets on model action", :save
    end

    context "with multiple backends" do
      before do
        other_backend = Class.new(backend_class)
        Article.translates :title,   backend: backend_class, cache: true
        Article.translates :content, backend: other_backend, cache: true
        @article = Article.create
      end

      shared_examples_for "cache that resets on model action" do |action|
        it "updates cache on both backends on #{action}" do
          title_backend = @article.title_translations
          content_backend = @article.content_translations
          title_backend.write(:en, "foo")
          content_backend.write(:en, "bar")
          expect(title_backend.read(:en)).to eq("foo")
          expect(content_backend.read(:en)).to eq("bar")
          @article.send(action)
          expect(title_backend.read(:en)).to eq(nil)
          expect(content_backend.read(:en)).to eq(nil)
        end
      end

      it_behaves_like "cache that resets on model action", :reload
      it_behaves_like "cache that resets on model action", :save
    end
  end
end
