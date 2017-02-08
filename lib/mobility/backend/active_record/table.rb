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

      def self.configure!(options)
        table_name = options[:model_class].table_name
        options[:table_name]  ||= "#{table_name.singularize}_translations"
        options[:foreign_key] ||= table_name.downcase.singularize.camelize.foreign_key
        if (association_name = options[:association_name]).present?
          options[:subclass_name] ||= association_name.to_s.singularize.camelize
        else
          options[:association_name] = :mobility_model_translations
          options[:subclass_name] ||= :Translation
        end
        %i[foreign_key association_name subclass_name].each { |key| options[key] = options[key].to_sym }
      end

      setup do |attributes, options|
        association_name = options[:association_name]
        subclass_name    = options[:subclass_name]

        attr_accessor :"__#{association_name}_cache"

        translation_class =
          if self.const_defined?(subclass_name, false)
            const_get(subclass_name, false)
          else
            const_set(subclass_name, Class.new(Mobility::ActiveRecord::ModelTranslation))
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

        query_methods = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend query_methods
      end

      def new_cache
        reset_model_cache unless model_cache
        model_cache.for(attribute)
      end

      def write_to_cache?
        true
      end

      def clear_cache
        model_cache.try(:clear)
      end

      private

      def translation_for(locale)
        translation = translations.find { |t| t.locale == locale.to_s }
        translation ||= translations.build(locale: locale)
        translation
      end

      def translations
        model.send(association_name)
      end

      def model_cache
        model.send(:"__#{association_name}_cache")
      end

      def reset_model_cache
        model.send(:"__#{association_name}_cache=",
                   Table::TranslationsCache.new { |locale| translation_for(locale) })
      end
    end
  end
end
