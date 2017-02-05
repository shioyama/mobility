module Mobility
  module Backend
    class Sequel::Table
      include Backend

      autoload :QueryMethods, 'mobility/backend/sequel/table/query_methods'

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
        raise CacheRequired, "Cache required for Sequel::Table backend" if options[:cache] == false
        table_name = options[:model_class].table_name
        options[:table_name]       ||= :"#{table_name.to_s.gsub(/s$/, '')}_translations"
        options[:foreign_key]      ||= :"#{table_name.downcase.to_s.gsub!(/s$/, '').camelize.foreign_key}"
        options[:association_name] ||= :mobility_model_translations
        %i[table_name foreign_key association_name].each { |key| options[key] = options[key].to_sym }
      end

      setup do |attributes, options|
        association_name = options[:association_name]

        attr_accessor :mobility_translations_cache

        translation_class =
          if self.const_defined?(:Translation, false)
            const_get(:Translation, false)
          else
            const_set(:Translation, Class.new(::Sequel::Model(options[:table_name]))).tap do |klass|
              klass.include ::Mobility::Sequel::ModelTranslation
            end
          end

        one_to_many association_name,
          class:      translation_class.name,
          key:        options[:foreign_key],
          reciprocal: :translated_model

        translation_class.many_to_one :translated_model,
          class:      name,
          key:        options[:foreign_key],
          reciprocal: association_name

        plugin :association_dependencies, association_name => :destroy

        callback_methods = Module.new do
          define_method :after_save do
            super()
            mobility_translations_cache.each_value do |translation|
              translation.id ? translation.save : send("add_#{association_name.to_s.singularize}", translation)
            end if mobility_translations_cache
          end
        end
        include callback_methods

        define_method :mobility_translation_for do |locale|
          translation = send(association_name).find { |t| t.locale == locale.to_s }
          translation ||= translation_class.new(locale: locale)
          translation
        end

        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension

        include Mobility::Sequel::ColumnChanges.new(attributes)
      end

      def new_cache
        (model.mobility_translations_cache ||= Table::TranslationsCache.new(model)).for(attribute)
      end

      def write_to_cache?
        true
      end

      def clear_cache
        model.mobility_translations_cache if model.mobility_translations_cache
      end

      class CacheRequired < ::StandardError; end
    end
  end
end
