module Mobility
  module Backend
    class ActiveRecord::KeyValue
      include Backend

      autoload :QueryMethods, 'mobility/backend/active_record/key_value/query_methods'

      attr_reader :association_name

      def initialize(model, attribute, **options)
        super
        @association_name = options[:association_name]
      end

      def read(locale, **options)
        translation_for(locale).value
      end

      def write(locale, value, **options)
        translation_for(locale).tap { |t| t.value = value }.value
      end

      def self.configure!(options)
        if type = options[:type]
          case type.to_sym
          when :text, :string
            options[:class_name] = Mobility::ActiveRecord.const_get("#{type.capitalize}Translation")
          else
            raise ArgumentError, "type must be one of: [text, string]"
          end
        end
        options[:class_name]       ||= Mobility::ActiveRecord::TextTranslation
        options[:class_name] = options[:class_name].constantize if options[:class_name].is_a?(String)
        options[:association_name] ||= options[:class_name].table_name.to_sym
      end

      setup do |attributes, options|
        association_name   = options[:association_name]
        translations_class = options[:class_name]

        # Track all attributes for this association, so that we can limit the scope
        # of keys for the association to only these attributes. We need to track the
        # attributes assigned to the association in case this setup code is called
        # multiple times, so we don't "forget" earlier attributes.
        #
        attrs_method_name = :"#{association_name}_attributes"
        association_attributes = (instance_variable_get(:"@#{attrs_method_name}") || []) + attributes
        instance_variable_set(:"@#{attrs_method_name}", association_attributes)

        has_many association_name, ->{ where key: association_attributes },
          as: :translatable,
          class_name: translations_class,
          dependent:  :destroy,
          inverse_of: :translatable,
          autosave:   true
        before_save do
          send(association_name).select { |t| t.value.blank? }.each do |translation|
            send(association_name).delete(translation)
          end
        end

        mod = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend mod
      end

      def new_cache
        KeyValue::TranslationsCache.new(self)
      end

      def write_to_cache?
        true
      end

      def translation_for(locale)
        translation = translations.find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= translations.build(locale: locale, key: attribute)
        translation
      end

      def translations
        model.send(association_name)
      end
    end
  end
end
