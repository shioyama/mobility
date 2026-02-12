require "spec_helper"

return unless defined?(ActiveRecord)

require "mobility/plugins/active_record/dirty"
require "mobility/plugins/active_record/column_fallback"

describe "Dirty with ColumnFallback", orm: :active_record, type: :plugin do
  plugins do
    dirty true
    active_record
    reader
    writer
    column_fallback true
  end

  plugin_setup :slug

  let(:model_class) do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include translations

    changes_applied_method = ::ActiveRecord::VERSION::STRING < '5.1' ? :changes_applied : :changes_internally_applied
    Article.class_eval do
      define_method changes_applied_method do
        super()
      end

      def previous_changes
        super
      end

      def clear_changes_information
        super
      end
    end

    Article
  end

  let(:backend_class) do
    Class.new do
      include Mobility::Backend
      def read(locale, **)
        values[locale]
      end

      def write(locale, value, **)
        values[locale] = value
      end

      private
      def values; @values ||= {}; end
    end
  end

  describe "tracking changes with column fallback" do
    it "tracks changes in default locale (column fallback)" do
      Mobility.locale = :en
      instance = model_class.create

      aggregate_failures "before change" do
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      instance.slug = "foo"

      aggregate_failures "after change" do
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to include("slug_en")
        expect(instance.changes).to include("slug_en" => [nil, "foo"])
      end
    end

    it "tracks changes in non-default locale" do
      Mobility.locale = :fr
      instance = model_class.create

      aggregate_failures "before change" do
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      instance.slug = "bonjour"

      aggregate_failures "after change" do
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to include("slug_fr")
        expect(instance.changes).to include("slug_fr" => [nil, "bonjour"])
      end
    end
  end
end
