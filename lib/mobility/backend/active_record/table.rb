module Mobility
  module Backend
    class ActiveRecord::Table
      include Backend

      autoload :QueryMethods, 'mobility/backend/active_record/table/query_methods'

      attr_reader :association_name

      def initialize(model, attribute, **options)
        super
        @association_name = options[:association_name]
      end

      def read(locale, **options)
        translation_for(locale).send(attribute)
      end

      def write(locale, value, **options)
        translation_for(locale).tap { |t| t.send("#{attribute}=", value) }.send(attribute)
      end

      def translation_for(locale)
        model.mobility_translation_for(locale)
      end

      def self.configure!(options)
        table_name = options[:model_class].table_name
        options[:table_name]       ||= "#{table_name.singularize}_translations"
        options[:foreign_key]      ||= table_name.downcase.singularize.camelize.foreign_key
        options[:association_name] ||= :mobility_model_translations
      end

      setup do |attributes, options|
        association_name = options[:association_name]

        attr_accessor :mobility_translations_cache

        translation_class =
          if self.const_defined?(:Translation, false)
            const_get(:Translation, false)
          else
            const_set(:Translation, Class.new(Mobility::ActiveRecord::ModelTranslation))
          end

        translation_class.table_name = options[:table_name]

        has_many association_name,
          class_name:  translation_class.name,
          foreign_key: options[:foreign_key],
          dependent:   :destroy,
          autosave:    true,
          inverse_of:  :translated_model

        translation_class.belongs_to :translated_model,
          class_name:  name,
          foreign_key: options[:foreign_key],
          inverse_of:  association_name

        define_method :mobility_translation_for do |locale|
          translation = send(association_name).find { |t| t.locale == locale.to_s }
          translation ||= send(association_name).build(locale: locale)
          translation
        end

        query_methods = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend query_methods
      end

      def new_cache
        (model.mobility_translations_cache ||= Table::TranslationsCache.new(model)).for(attribute)
      end

      def write_to_cache?
        true
      end

      def clear_cache
        model.mobility_translations_cache.try(:clear)
      end
    end
  end
end
