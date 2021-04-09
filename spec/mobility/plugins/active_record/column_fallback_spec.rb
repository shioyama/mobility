require "spec_helper"

return unless defined?(ActiveRecord)

require "mobility/plugins/active_record/column_fallback"

describe Mobility::Plugins::ActiveRecord::ColumnFallback, orm: :active_record, type: :plugin do
  plugins :active_record, :reader, :writer, :column_fallback

  let(:model_class) do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include translations
    Article
  end

  context "column_fallback: true" do
    plugin_setup :slug, column_fallback: true

    it "reads/writes from/to model column if locale is I18n.default_locale" do
      instance.send(:write_attribute, :slug, "foo")

      Mobility.with_locale(:en) do
        expect(instance.slug).to eq("foo")
        instance.slug = "bar"
        expect(instance.slug).to eq("bar")
        expect(instance.read_attribute(:slug)).to eq("bar")
      end
    end

    it "reads/writes from/to backend if locale is not I18n.default_locale" do
      instance.send(:write_attribute, :slug, "foo")

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
        instance.send(:write_attribute, :slug, "foo")

        Mobility.with_locale(locale) do
          expect(instance.slug).to eq("foo")
          instance.slug = "bar"
          expect(instance.slug).to eq("bar")
          expect(instance.read_attribute(:slug)).to eq("bar")
        end
      end
    end

    it "reads/writes from/to backend if locale is not in locales array" do
      instance.send(:write_attribute, :slug, "foo")

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
      instance.send(:write_attribute, :slug, "foo")

      Mobility.with_locale(:de) do
        expect(instance.slug).to eq("foo")
        instance.slug = "bar"
        expect(instance.slug).to eq("bar")
        expect(instance.read_attribute(:slug)).to eq("bar")
      end
    end

    it "reads/writes from/to backend if proc returns true" do
      instance.send(:write_attribute, :slug, "foo")

      Mobility.with_locale(:fr) do
        expect(listener).to receive(:read).with(:fr, any_args).and_return("bar")
        expect(instance.slug).to eq("bar")

        expect(listener).to receive(:write).with(:fr, "baz", any_args)
        instance.slug = "baz"
      end
    end
  end

  describe "querying" do
    plugins :active_record, :writer, :query, :column_fallback

    let(:model_class) do
      stub_const 'Article', Class.new(ActiveRecord::Base)
    end

    context "column_fallback: true" do
      before do
        translates model_class, :slug, backend: [:key_value, type: :string], column_fallback: true
      end

      it "queries on model column if locale is I18n.default_locale" do
        instance1 = model_class.new
        instance1.send(:write_attribute, :slug, "foo")
        instance1.save

        instance2 = model_class.new
        Mobility.with_locale(:fr) { instance2.slug = "bar" }
        instance2.save

        expect(model_class.i18n.find_by(slug: "foo", locale: :en)).to eq(instance1)
        expect(model_class.i18n.find_by(slug: "foo", locale: :fr)).to eq(nil)
        expect(model_class.i18n.find_by(slug: "bar", locale: :fr)).to eq(instance2)
        expect(model_class.i18n.find_by(slug: "bar", locale: :en)).to eq(nil)
      end
    end

    locales = [:de, :ja]
    context "column_fallback: #{locales.inspect}" do
      before do
        translates model_class, :slug, backend: [:key_value, type: :string], column_fallback: locales
      end

      it "queries on model column if locale is locales array" do
        instance1 = model_class.new
        Mobility.with_locale(:de) { instance1.send(:write_attribute, :slug, "foo") }
        instance1.save

        instance2 = model_class.new
        Mobility.with_locale(:ja) { instance2.send(:write_attribute, :slug, "bar") }
        instance2.save

        instance3 = model_class.new
        Mobility.with_locale(:en) { instance3.slug = "baz" }
        instance3.save

        expect(model_class.i18n.find_by(slug: "foo", locale: :de)).to eq(instance1)
        expect(model_class.i18n.find_by(slug: "foo", locale: :en)).to eq(nil)
        expect(model_class.i18n.find_by(slug: "bar", locale: :ja)).to eq(instance2)
        expect(model_class.i18n.find_by(slug: "bar", locale: :en)).to eq(nil)
        expect(model_class.i18n.find_by(slug: "baz", locale: :en)).to eq(instance3)
        expect(model_class.i18n.find_by(slug: "baz", locale: :de)).to eq(nil)
      end
    end

    context "column_fallback: ->(locale) { locale == :de }" do
      before do
        translates model_class, :slug, backend: [:key_value, type: :string], column_fallback: ->(locale) { locale == :de }
      end

      it "queries on model column if proc returns false" do
        instance1 = model_class.new
        Mobility.with_locale(:de) { instance1.send(:write_attribute, :slug, "foo") }
        instance1.save

        instance2 = model_class.new
        Mobility.with_locale(:ja) { instance2.slug = "bar" }
        instance2.save

        expect(model_class.i18n.find_by(slug: "foo", locale: :de)).to eq(instance1)
        expect(model_class.i18n.find_by(slug: "foo", locale: :ja)).to eq(nil)
        expect(model_class.i18n.find_by(slug: "bar", locale: :ja)).to eq(instance2)
        expect(model_class.i18n.find_by(slug: "bar", locale: :de)).to eq(nil)
      end
    end
  end
end
