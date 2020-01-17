require "spec_helper"
require "mobility/plugins/cache"

describe Mobility::Plugins::Cache do
  include Helpers::Plugins

  describe "backend methods" do
    plugin_setup cache: true, these: "options"

    let(:locale) { :cz }
    let(:options) { { these: "options" } }

    describe "#read" do
      it "caches reads" do
        expect(listener).to receive(:read).once.with(locale, options).and_return("foo")
        2.times { expect(backend.read(locale, **options)).to eq("foo") }
      end

      it "does not cache reads with cache: false option" do
        expect(listener).to receive(:read).twice.with(locale, options).and_return("foo")
        2.times { expect(backend.read(locale, **options.merge(cache: false))).to eq("foo") }
      end

      it "does not modify options passed in" do
        allow(listener).to receive(:read).with(locale, {}).and_return("foo")
        options = { cache: false }
        backend.read(locale, **options)
        expect(options).to eq({ cache: false })
      end
    end

    describe "#write" do
      it "returns value fetched from backend" do
        expect(listener).to receive(:write).twice.with(locale, "foo", options).and_return("bar")
        2.times { expect(backend.write(locale, "foo", **options)).to eq("bar") }
      end

      it "stores value fetched from backend in cache" do
        expect(listener).to receive(:write).once.with(locale, "foo", options).and_return("bar")
        expect(backend.write(locale, "foo", **options)).to eq("bar")
        expect(listener).not_to receive(:read)
        expect(backend.read(locale, **options)).to eq("bar")
      end

      it "does not store value in cache with cache: false option" do
        allow(listener).to receive(:write).once.with(locale, "foo", options).and_return("bar")
        expect(backend.write(locale, "foo", **options.merge(cache: false))).to eq("bar")
        expect(listener).to receive(:read).with(locale, options).and_return("baz")
        expect(backend.read(locale, **options)).to eq("baz")
      end

      it "does not modify options passed in" do
        allow(listener).to receive(:write).with(locale, "foo", {})
        options = { cache: false }
        backend.write(locale, "foo", **options)
        expect(options).to eq({ cache: false })
      end
    end
  end

  describe "resetting cache on actions" do
    shared_examples_for "cache that resets on model action" do |action, options = nil|
      it "updates backend cache on #{action}" do
        aggregate_failures "reading and writing" do
          expect(listener).to receive(:write).with(:en, "foo", {}).and_return("foo set")
          backend.write(:en, "foo")
          expect(backend.read(:en)).to eq("foo set")
        end

        aggregate_failures "resetting model" do
          options ? instance.send(action, options) : instance.send(action)
          expect(listener).to receive(:read).with(:en, {}).and_return("from backend")
          expect(backend.read(:en)).to eq("from backend")
        end
      end
    end

    shared_examples_for "cache that resets on model action with multiple backends" do |action, options = nil|
      it "updates cache on both backends on #{action}" do
        aggregate_failures "reading and writing" do
          expect(listener).to receive(:write).with(:en, "foo", {}).and_return("foo set")
          expect(content_listener).to receive(:write).with(:en, "bar", {}).and_return("bar set")
          backend.write(:en, "foo")
          instance.content_backend.write(:en, "bar")
          expect(backend.read(:en)).to eq("foo set")
          expect(instance.content_backend.read(:en)).to eq("bar set")
        end

        aggregate_failures "resetting model" do
          options ? instance.send(action, options) : instance.send(action)
          expect(listener).to receive(:read).with(:en, {}).and_return("from title backend")
          expect(backend.read(:en)).to eq("from title backend")
          expect(content_listener).to receive(:read).with(:en, {}).and_return("from content backend")
          expect(instance.content_backend.read(:en)).to eq("from content backend")
        end
      end
    end

    context "ActiveRecord model", orm: :active_record do
      context "with one backend" do
        plugin_setup cache: true

        let(:model_class) do
          stub_const 'Article', Class.new(ActiveRecord::Base)
          Article.include attributes
        end
        let(:instance) { model_class.create }

        it_behaves_like "cache that resets on model action", :reload
        it_behaves_like "cache that resets on model action", :reload, { readonly: true, lock: true }
        it_behaves_like "cache that resets on model action", :save

        # borrowed from dirty plugin specs
        %w[changes_applied clear_changes_information].each do |method_name|
          it "does not change private status of #{method_name}" do
            # Create a dummy vanilla AR model so we can inspect its methods and
            # ensure we haven't made anything that was private, public. By
            # doing it like this, we ensure that the test works for all
            # versions of Rails (private/public status of various methods has
            # changed between versions.)
            klass = Class.new(ActiveRecord::Base) do
              self.table_name = 'articles'
            end
            ar = klass.new

            expect(instance.respond_to?(method_name)).to eq(ar.respond_to?(method_name))
            expect(instance.respond_to?(method_name, true)).to eq(ar.respond_to?(method_name, true))
          end
        end
      end

      context "with multiple backends" do
        plugin_setup "title", cache: true

        let(:instance) { model_class.create }
        let(:content_listener) { double(:backend) }
        let(:model_class) do
          stub_const 'Article', Class.new(ActiveRecord::Base)
          Article.include attributes
          Article.include attributes_class.new("content", backend: backend_listener(content_listener), cache: true)
          Article
        end
        it_behaves_like "cache that resets on model action with multiple backends", :reload
        it_behaves_like "cache that resets on model action with multiple backends", :reload, { readonly: true, lock: true }
        it_behaves_like "cache that resets on model action with multiple backends", :save
      end
    end

    context "Sequel model", orm: :sequel do
      context "with one backend" do
        plugin_setup "title", cache: true
        let(:instance) { model_class.create }
        let(:model_class) do
          stub_const 'Article', Class.new(Sequel::Model)
          Article.dataset = DB[:articles]
          Article.include attributes
          Article
        end

        it_behaves_like "cache that resets on model action", :refresh
      end

      context "with multiple backends" do
        plugin_setup "title", cache: true

        let(:instance) { model_class.create }
        let(:content_listener) { double(:backend) }
        let(:model_class) do
          stub_const 'Article', Class.new(Sequel::Model)
          Article.dataset = DB[:articles]
          Article.include attributes
          Article.include attributes_class.new("content", backend: backend_listener(content_listener), cache: true)
          Article
        end
        it_behaves_like "cache that resets on model action with multiple backends", :refresh
      end
    end
  end
end
