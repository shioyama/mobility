require "spec_helper"

describe Mobility::Plugins::Sequel::Dirty, orm: :sequel do
  include Helpers::Plugins
  plugin_setup "title", dirty: true, sequel: true, reader: true, writer: true

  let(:model_class) do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
    Article.include attributes
    Article
  end

  let(:backend_class) do
    Class.new(Mobility::Backends::Null) do
      def read(locale, **options)
        values[locale]
      end

      def write(locale, value, **options)
        values[locale] = value
      end

      private

      def values
        @values ||= {}
      end
    end
  end

  it "loads sequel dirty plugin" do
    expect(model_class.plugins).to include(::Sequel::Plugins::Dirty)
  end

  describe "tracking changes" do
    it "tracks changes in one locale" do
      Mobility.locale = :'pt-BR'
      instance = model_class.new

      aggregate_failures "before change" do
        expect(instance.title).to eq(nil)
        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.column_change(:title)).to eq(nil)
        expect(instance.changed_columns).to eq([])
        expect(instance.column_changes).to eq({})
      end

      aggregate_failures "set same value" do
        instance.title = nil
        expect(instance.title).to eq(nil)
        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.column_change(:title)).to eq(nil)
        expect(instance.changed_columns).to eq([])
        expect(instance.column_changes).to eq({})
      end

      instance.title = "foo"

      aggregate_failures "after change" do
        expect(instance.title).to eq("foo")
        expect(instance.column_changed?(:title)).to eq(true)
        expect(instance.column_change(:title)).to eq([nil, "foo"])
        expect(instance.changed_columns).to eq([:title_pt_br])
        expect(instance.column_changes).to eq({ :title_pt_br => [nil, "foo"] })
      end
    end

    it "tracks previous changes in one locale" do
      instance = model_class.create(title: "foo")

      aggregate_failures do
        instance.title = "bar"
        expect(instance.column_changed?(:title)).to eq(true)

        instance.save

        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.previous_changes).to include_hash({ :title_en => ["foo", "bar"]})
      end
    end

    it "tracks changes in multiple locales" do
      instance = model_class.new

      expect(instance.title).to eq(nil)

      aggregate_failures "change in English locale" do
        instance.title = "English title"

        expect(instance.column_changed?(:title)).to eq(true)
        expect(instance.changed_columns).to eq([:title_en])
        expect(instance.column_changes).to eq({ :title_en => [nil, "English title"] })
      end

      aggregate_failures "change in French locale" do
        Mobility.locale = :fr

        instance.title = "Titre en Francais"
        expect(instance.column_changed?(:title)).to eq(true)
        expect(instance.changed_columns).to match_array([:title_en, :title_fr])
        expect(instance.column_changes).to eq({ title_en: [nil, "English title"], title_fr: [nil, "Titre en Francais"] })
      end
    end

    it "tracks previous changes in multiple locales" do
      instance = model_class.new
      instance.title_en = "English title 1"
      instance.title_fr = "Titre en Francais 1"
      instance.save

      instance.title = "English title 2"
      Mobility.locale = :fr
      instance.title = "Titre en Francais 2"

      instance.save

      expect(instance.previous_changes).to include_hash(title_en: ["English title 1", "English title 2"],
                                                       title_fr: ["Titre en Francais 1", "Titre en Francais 2"])
    end

    it "resets changes when locale is set to original value" do
      instance = model_class.create(title: "foo")

      expect(instance.column_changed?(:title)).to eq(false)

      aggregate_failures "after change" do
        instance.title = "bar"
        expect(instance.column_changed?(:title)).to eq(true)
        expect(instance.changed_columns).to eq([:title_en])
        expect(instance.column_changes).to eq({ title_en: ["foo", "bar"] })
      end

      aggregate_failures "after setting attribute back to original value" do
        instance.title = "foo"
        expect(instance.changed_columns).to eq([])
        expect(instance.column_changes).to eq({})
        expect(instance.title).to eq("foo")
      end

      aggregate_failures "changing value in different locale" do
        Mobility.with_locale(:fr) { instance.title = "Titre en Francais" }

        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.changed_columns).to eq([:title_fr])
        expect(instance.column_changes).to eq({ title_fr: [nil, "Titre en Francais"] })

        Mobility.locale = :fr
        expect(instance.column_changed?(:title)).to eq(true)
      end
    end
  end

  describe "fallbacks compatiblity" do
    before do
      stub_const 'ArticleWithFallbacks', Class.new(Sequel::Model)
      ArticleWithFallbacks.class_eval do
        dataset = DB[:articles]
        extend Mobility
      end
      ArticleWithFallbacks.translates :title, backend: backend_class, dirty: true, cache: false, fallbacks: { en: 'ja' }
    end

    it "does not compare with fallback value" do
      instance = ArticleWithFallbacks.new

      aggregate_failures "before change" do
        expect(instance.title).to eq(nil)
        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.column_change(:title)).to eq(nil)
        expect(instance.changed_columns).to eq([])
        expect(instance.column_changes).to eq({})
      end

      aggregate_failures "set fallback locale value" do
        Mobility.with_locale(:ja) { instance.title = "あああ" }
        expect(instance.title).to eq("あああ")
        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.column_change(:title)).to eq(nil)
        expect(instance.changed_columns).to eq([:title_ja])
        expect(instance.column_changes).to eq({ title_ja: [nil, "あああ"]})
        Mobility.with_locale(:ja) { expect(instance.title).to eq("あああ") }
      end

      aggregate_failures "set value in current locale to same value" do
        instance.title = nil
        expect(instance.title).to eq("あああ")
        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.column_change(:title)).to eq(nil)
        expect(instance.changed_columns).to eq([:title_ja])
        expect(instance.column_changes).to eq({ title_ja: [nil, "あああ"]})
      end

      aggregate_failures "set value in fallback locale to different value" do
        Mobility.with_locale(:ja) { instance.title = "ばばば" }
        expect(instance.title).to eq("ばばば")
        expect(instance.column_changed?(:title)).to eq(false)
        expect(instance.column_change(:title)).to eq(nil)
        expect(instance.changed_columns).to eq([:title_ja])
        expect(instance.column_changes).to eq({ title_ja: [nil, "ばばば"]})
      end

      aggregate_failures "set value in current locale to different value" do
        instance.title = "Title"
        expect(instance.title).to eq("Title")
        expect(instance.column_changed?(:title)).to eq(true)
        expect(instance.column_change(:title)).to eq([nil, "Title"])
        expect(instance.changed_columns).to match_array([:title_ja, :title_en])
        expect(instance.column_changes).to eq({ title_ja: [nil, "ばばば"], title_en: [nil, "Title"]})
      end
    end
  end

  %i[initial_value column_change column_changed? reset_column].each do |method_name|
    it "does not change visibility of #{method_name}" do
      # Create a dummy Sequel model so we can inspect its dirty methods.
      klass = Class.new(Sequel::Model)
      klass.plugin :dirty
      dirty = klass.new

      expect(instance.respond_to?(method_name)).to eq(dirty.respond_to?(method_name))
      expect(instance.respond_to?(method_name, true)).to eq(true)
      expect(dirty.respond_to?(method_name, true)).to eq(true)
    end
  end
end if defined?(Sequel)
