require "spec_helper"

describe Mobility::Plugins::Cache do
  describe "when included into a class" do
    let(:backend_class) do
      Class.new(Mobility::Backends::Null) do
        def read(*args)
          spy.read(*args)
        end

        def write(*args)
          spy.write(*args)
        end

        def spy
          @backend_double ||= RSpec::Mocks::Double.new("backend")
        end
      end
    end
    let(:cached_backend_class) { Class.new(backend_class).include(described_class) }
    let(:options) { { these: "options" } }
    let(:locale) { :cz }

    describe "#read" do
      it "caches reads" do
        backend = cached_backend_class.new("model", "attribute")
        expect(backend.spy).to receive(:read).once.with(locale, options).and_return("foo")
        2.times { expect(backend.read(locale, options)).to eq("foo") }
      end

      it "does not cache reads with cache: false option" do
        backend = cached_backend_class.new("model", "attribute")
        expect(backend.spy).to receive(:read).twice.with(locale, options).and_return("foo")
        2.times { expect(backend.read(locale, options.merge(cache: false))).to eq("foo") }
      end

      it "does not modify options passed in" do
        backend = cached_backend_class.new("model", "attribute")
        allow(backend.spy).to receive(:read).with(locale, {}).and_return("foo")
        options = { cache: false }
        backend.read(locale, options)
        expect(options).to eq({ cache: false })
      end
    end

    describe "#write" do
      it "returns value fetched from backend" do
        backend = cached_backend_class.new("model", "attribute")
        expect(backend.spy).to receive(:write).twice.with(locale, "foo", options).and_return("bar")
        2.times { expect(backend.write(locale, "foo", options)).to eq("bar") }
      end

      it "stores value fetched from backend in cache" do
        backend = cached_backend_class.new("model", "attribute")
        expect(backend.spy).to receive(:write).once.with(locale, "foo", options).and_return("bar")
        expect(backend.write(locale, "foo", options)).to eq("bar")
        expect(backend.spy).not_to receive(:read)
        expect(backend.read(locale, options)).to eq("bar")
      end

      it "does not store value in cache with cache: false option" do
        backend = cached_backend_class.new("model", "attribute")
        allow(backend.spy).to receive(:write).once.with(locale, "foo", options).and_return("bar")
        expect(backend.write(locale, "foo", options.merge(cache: false))).to eq("bar")
        expect(backend.spy).to receive(:read).with(locale, options).and_return("baz")
        expect(backend.read(locale, options)).to eq("baz")
      end

      it "does not modify options passed in" do
        backend = cached_backend_class.new("model", "attribute")
        allow(backend.spy).to receive(:write).with(locale, "foo", {})
        options = { cache: false }
        backend.write(locale, "foo", options)
        expect(options).to eq({ cache: false })
      end
    end

    describe "resetting cache on actions" do
      shared_examples_for "cache that resets on model action" do |action, options = nil|
        it "updates backend cache on #{action}" do
          backend = @article.mobility_backend_for("title")

          aggregate_failures "reading and writing" do
            expect(backend.spy).to receive(:write).with(:en, "foo", {}).and_return("foo set")
            backend.write(:en, "foo")
            expect(backend.read(:en)).to eq("foo set")
          end

          aggregate_failures "resetting model" do
            options ? @article.send(action, options) : @article.send(action)
            expect(backend.spy).to receive(:read).with(:en, {}).and_return("from backend")
            expect(backend.read(:en)).to eq("from backend")
          end
        end
      end

      shared_examples_for "cache that resets on model action with multiple backends" do |action, options = nil|
        it "updates cache on both backends on #{action}" do
          title_backend = @article.mobility_backend_for("title")
          content_backend = @article.mobility_backend_for("content")

          aggregate_failures "reading and writing" do
            expect(title_backend.spy).to receive(:write).with(:en, "foo", {}).and_return("foo set")
            expect(content_backend.spy).to receive(:write).with(:en, "bar", {}).and_return("bar set")
            title_backend.write(:en, "foo")
            content_backend.write(:en, "bar")
            expect(title_backend.read(:en)).to eq("foo set")
            expect(content_backend.read(:en)).to eq("bar set")
          end

          aggregate_failures "resetting model" do
            options ? @article.send(action, options) : @article.send(action)
            expect(title_backend.spy).to receive(:read).with(:en, {}).and_return("from title backend")
            expect(title_backend.read(:en)).to eq("from title backend")
            expect(content_backend.spy).to receive(:read).with(:en, {}).and_return("from content backend")
            expect(content_backend.read(:en)).to eq("from content backend")
          end
        end
      end

      context "ActiveRecord model", orm: :active_record do
        before do
          stub_const 'Article', Class.new(ActiveRecord::Base)
          Article.include Mobility
        end

        context "with one backend" do
          before do
            Article.translates :title, backend: backend_class, cache: true
            @article = Article.create
          end

          it_behaves_like "cache that resets on model action", :reload
          it_behaves_like "cache that resets on model action", :reload, { readonly: true, lock: true }
          it_behaves_like "cache that resets on model action", :save
        end

        context "with multiple backends" do
          before do
            other_backend = Class.new(backend_class)
            Article.translates :title,   backend: backend_class, cache: true
            Article.translates :content, backend: other_backend, cache: true
            @article = Article.create
          end
          it_behaves_like "cache that resets on model action with multiple backends", :reload
          it_behaves_like "cache that resets on model action with multiple backends", :reload, { readonly: true, lock: true }
          it_behaves_like "cache that resets on model action with multiple backends", :save
        end
      end

      context "Sequel model", orm: :sequel do
        before do
          stub_const 'Article', Class.new(Sequel::Model)
          Article.dataset = DB[:articles]
          Article.include Mobility
        end

        context "with one backend" do
          before do
            Article.translates :title, backend: backend_class, cache: true
            @article = Article.create
          end

          it_behaves_like "cache that resets on model action", :refresh
        end

        context "with multiple backends" do
          before do
            other_backend = Class.new(backend_class)
            Article.translates :title,   backend: backend_class, cache: true
            Article.translates :content, backend: other_backend, cache: true
            @article = Article.create
          end
          it_behaves_like "cache that resets on model action with multiple backends", :refresh
        end
      end
    end
  end

  # this is identical to apply specs for Presence, and can probably be refactored
  describe ".apply" do
    before { stub_const 'Article', Class.new }

    context "option value is truthy" do
      it "includes Cache into backend class" do
        backend_class = Class.new do
          include Mobility::Backend
        end
        attributes = instance_double(Mobility::Attributes, backend_class: backend_class, model_class: Article, names: ["title"])
        expect(backend_class).to receive(:include).twice.with(described_class)
        described_class.apply(attributes, true)
        described_class.apply(attributes, [])
      end
    end

    context "option value is falsey" do
      it "does not include Cache into backend class" do
        attributes = instance_double(Mobility::Attributes)
        expect(attributes).not_to receive(:backend_class)
        described_class.apply(attributes, false)
        described_class.apply(attributes, nil)
      end
    end
  end
end
