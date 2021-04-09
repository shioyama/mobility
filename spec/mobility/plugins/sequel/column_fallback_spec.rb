require "spec_helper"

return unless defined?(Sequel)

require "mobility/plugins/sequel/column_fallback"

describe Mobility::Plugins::Sequel::ColumnFallback, orm: :sequel, type: :plugin do
  plugins :sequel, :backend, :reader, :writer, :column_fallback

  let(:model_class) do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
    Article.include translations
    Article
  end

  context "column_fallback: true" do
    plugin_setup :slug, column_fallback: true

    it "reads/writes from/to model column if locale is I18n.default_locale" do
      instance[:slug] = "foo"

      Mobility.with_locale(:en) do
        expect(instance.slug).to eq("foo")
        instance.slug = "bar"
        expect(instance.slug).to eq("bar")
        expect(instance[:slug]).to eq("bar")
      end
    end

    it "reads/writes from/to backend if locale is not I18n.default_locale" do
      instance[:slug] = "foo"

      Mobility.with_locale(:fr) do
        expect(listener).to receive(:read).with(:fr, any_args).and_return("bar")
        expect(instance.slug).to eq("bar")

        expect(listener).to receive(:write).with(:fr, "baz", any_args)
        instance.slug = "baz"
      end
    end
  end

  locales = [:de, :ja]
  context "column_fallback: #{locales.inspect}" do
    plugin_setup :slug, column_fallback: locales

    it "reads/writes from/to model column if locale is locales array" do
      locales.each do |locale|
        instance[:slug] = "foo"

        Mobility.with_locale(locale) do
          expect(instance.slug).to eq("foo")
          instance.slug = "bar"
          expect(instance.slug).to eq("bar")
          expect(instance[:slug]).to eq("bar")
        end
      end
    end

    it "reads/writes from/to backend if locale is not in locales array" do
      instance[:slug] = "foo"

      Mobility.with_locale(:fr) do
        expect(listener).to receive(:read).with(:fr, any_args).and_return("bar")
        expect(instance.slug).to eq("bar")

        expect(listener).to receive(:write).with(:fr, "baz", any_args)
        instance.slug = "baz"
      end
    end
  end

  context "column_fallback: ->(locale) { locale == :de }" do
    plugin_setup :slug, column_fallback: ->(locale) { locale == :de }

    it "reads/writes from/to model column if proc returns false" do
      instance[:slug] = "foo"

      Mobility.with_locale(:de) do
        expect(instance.slug).to eq("foo")
        instance.slug = "bar"
        expect(instance.slug).to eq("bar")
        expect(instance[:slug]).to eq("bar")
      end
    end

    it "reads/writes from/to backend if proc returns true" do
      instance[:slug] = "foo"

      Mobility.with_locale(:fr) do
        expect(listener).to receive(:read).with(:fr, any_args).and_return("bar")
        expect(instance.slug).to eq("bar")

        expect(listener).to receive(:write).with(:fr, "baz", any_args)
        instance.slug = "baz"
      end
    end
  end

  describe "querying" do
    # need to include because Sequel KeyValue backend depends on it, and we're
    # using that backend in tests below
    plugins :sequel, :writer, :query, :cache, :column_fallback

    let(:model_class) do
      stub_const 'Article', Class.new(Sequel::Model)
      Article.dataset = DB[:articles]
      Article
    end

    context "column_fallback: true" do
      before do
        translates model_class, :slug, backend: [:key_value, type: :string], column_fallback: true
      end

      it "queries on model column if locale is I18n.default_locale" do
        instance1 = model_class.new
        instance1[:slug] = "foo"
        instance1.save

        instance2 = model_class.new
        Mobility.with_locale(:fr) { instance2.slug = "bar" }
        instance2.save

        expect(model_class.i18n.where(slug: "foo", locale: :en).select_all(:articles).all).to match_array([instance1])
        expect(model_class.i18n.where(slug: "foo", locale: :fr).select_all(:articles).all).to eq([])
        expect(model_class.i18n.where(slug: "bar", locale: :fr).select_all(:articles).all).to eq([instance2])
        expect(model_class.i18n.where(slug: "bar", locale: :en).select_all(:articles).all).to eq([])
      end
    end

    locales = [:de, :ja]
    context "column_fallback: #{locales.inspect}" do
      before do
        translates model_class, :slug, backend: [:key_value, type: :string], column_fallback: locales
      end

      it "queries on model column if locale is locales array" do
        instance1 = model_class.new
        Mobility.with_locale(:de) { instance1.slug = "foo" }
        instance1.save

        instance2 = model_class.new
        Mobility.with_locale(:ja) { instance2.slug = "bar" }
        instance2.save

        instance3 = model_class.new
        Mobility.with_locale(:en) { instance3.slug = "baz" }
        instance3.save

        expect(model_class.i18n.where(slug: "foo", locale: :de).select_all(:articles).all).to eq([instance1])
        expect(model_class.i18n.where(slug: "foo", locale: :en).select_all(:articles).all).to eq([])
        expect(model_class.i18n.where(slug: "bar", locale: :ja).select_all(:articles).all).to eq([instance2])
        expect(model_class.i18n.where(slug: "bar", locale: :en).select_all(:articles).all).to eq([])
        expect(model_class.i18n.where(slug: "baz", locale: :en).select_all(:articles).all).to eq([instance3])
        expect(model_class.i18n.where(slug: "baz", locale: :de).select_all(:articles).all).to eq([])
      end
    end

    context "column_fallback: ->(locale) { locale == :de }" do
      before do
        translates model_class, :slug, backend: [:key_value, type: :string], column_fallback: ->(locale) { locale == :de }
      end

      it "queries on model column if proc returns false" do
        instance1 = model_class.new
        Mobility.with_locale(:de) { instance1.slug = "foo" }
        instance1.save

        instance2 = model_class.new
        Mobility.with_locale(:ja) { instance2.slug = "bar" }
        instance2.save

        expect(model_class.i18n.where(slug: "foo", locale: :de).select_all(:articles).all).to eq([instance1])
        expect(model_class.i18n.where(slug: "foo", locale: :ja).select_all(:articles).all).to eq([])
        expect(model_class.i18n.where(slug: "bar", locale: :ja).select_all(:articles).all).to eq([instance2])
        expect(model_class.i18n.where(slug: "bar", locale: :de).select_all(:articles).all).to eq([])
      end
    end
  end
end
