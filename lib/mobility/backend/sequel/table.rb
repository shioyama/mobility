module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Table} backend for Sequel models.

=end
    class Sequel::Table
      include Backend

      autoload :QueryMethods, 'mobility/backend/sequel/table/query_methods'

      # @return [Symbol] name of the association method
      attr_reader :association_name

      # @return [Symbol] class for translations
      attr_reader :translation_class

      # @!macro backend_constructor
      # @option options [Symbol] association_name Name of association
      def initialize(model, attribute, **options)
        super
        @association_name  = options[:association_name]
        @translation_class = options[:model_class].const_get(options[:subclass_name])
      end

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, **_)
        translation_for(locale).send(attribute)
      end

      # @!macro backend_reader
      def write(locale, value, **_)
        translation_for(locale).tap { |t| t.send("#{attribute}=", value) }.send(attribute)
      end

      # @!group Backend Configuration
      # @option options [Symbol] association_name (:mobility_model_translations) Name of association method
      # @option options [Symbol] table_name Name of translation table
      # @option options [Symbol] foreign_key Name of foreign key
      # @option options [Symbol] subclass_name Name of subclass to append to model class to generate translation class
      # @raise [CacheRequired] if cache option is false
      def self.configure(options)
        raise CacheRequired, "Cache required for Sequel::Table backend" if options[:cache] == false
        table_name = options[:model_class].table_name
        options[:table_name]  ||= :"#{table_name.to_s.singularize}_translations"
        options[:foreign_key] ||= table_name.to_s.downcase.singularize.camelize.foreign_key
        if (association_name = options[:association_name]).present?
          options[:subclass_name] ||= association_name.to_s.singularize.camelize
        else
          options[:association_name] = :mobility_model_translations
          options[:subclass_name] ||= :Translation
        end
        %i[table_name foreign_key association_name subclass_name].each { |key| options[key] = options[key].to_sym }
      end
      # @!endgroup

      setup do |attributes, options|
        association_name = options[:association_name]
        subclass_name    = options[:subclass_name]

        cache_accessor_name = :"__#{association_name}_cache"

        attr_accessor cache_accessor_name

        translation_class =
          if self.const_defined?(subclass_name, false)
            const_get(subclass_name, false)
          else
            const_set(subclass_name, Class.new(::Sequel::Model(options[:table_name]))).tap do |klass|
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
            send(cache_accessor_name).each_value do |translation|
              translation.id ? translation.save : send("add_#{association_name.to_s.singularize}", translation)
            end if send(cache_accessor_name)
          end
        end
        include callback_methods

        extension = Module.new do
          define_method ::Mobility.query_method do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension

        include Mobility::Sequel::ColumnChanges.new(attributes)
      end

      # @!group Cache Methods
      # @return [Table::TranslationsCache]
      def new_cache
        reset_model_cache unless model_cache
        model_cache.for(attribute)
      end

      # @return [Boolean]
      def write_to_cache?
        true
      end

      def clear_cache
        model_cache.clear if model_cache
      end
      # @!endgroup

      private

      def translation_for(locale)
        translation = translations.find { |t| t.locale == locale.to_s }
        translation ||= translation_class.new(locale: locale)
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

      class CacheRequired < ::StandardError; end
    end
  end
end
