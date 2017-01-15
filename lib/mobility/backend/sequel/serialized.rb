module Mobility
  module Backend
    class Sequel::Serialized
      autoload :QueryMethods, 'mobility/backend/sequel/serialized/query_methods'
      include Base

      def read(locale, **options)
        translations[locale]
      end

      def write(locale, value, **options)
        translations[locale] = value
      end

      def self.configure!(options)
        options[:format] ||= :yaml
        options[:format] = options[:format].downcase.to_sym
        raise ArgumentError, "Serialized backend only supports yaml or json formats." unless [:yaml, :json].include?(options[:format])
      end

      setup do |attributes, options|
        format = options[:format]
        plugin :serialization
        plugin :serialization_modification_detection

        attributes.each do |_attribute|
          attribute = _attribute.to_sym
          self.serialization_map[attribute] = Serialized.serializer_for(format)
          self.deserialization_map[attribute] = Serialized.deserializer_for(format)
        end

        method_overrides = Module.new do
          define_method :initialize_set do |values|
            attributes.each { |attribute| send(:"#{attribute}_before_mobility=", {}.send(:"to_#{format}")) }
            super(values)
          end
        end
        include method_overrides

        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension

        include SerializationModificationDetectionFix
      end

      def translations
        _attribute = attribute.to_sym
        if model.deserialized_values.has_key?(_attribute)
          model.deserialized_values[_attribute]
        elsif model.frozen?
          deserialize_value(_attribute, serialized_value)
        else
          model.deserialized_values[_attribute] = deserialize_value(_attribute, serialized_value)
        end
      end

      def new_cache
        translations
      end

      def write_to_cache?
        true
      end

      # This is basically a depth-two dup of the deserialized values, necessary in order to assure we
      # have a distinct copy for all locales. The original serialization modification detection plugin
      # just points original_deserialized_values to deserialized_values, which prevents detection of
      # changes.
      module SerializationModificationDetectionFix
        def after_save
          super()
          @original_deserialized_values = @deserialized_values.inject({}) { |vs, (col, trs)| vs[col] = trs.dup; vs}
        end
      end

      private

      def deserialize_value(column, value)
        model.send(:deserialize_value, column, value)
      end

      def serialized_value
        model.send("#{attribute}_before_mobility")
      end
    end
  end
end
