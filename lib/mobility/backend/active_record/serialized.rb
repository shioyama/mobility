module Mobility
  module Backend
    class ActiveRecord::Serialized
      autoload :QueryMethods, 'mobility/backend/active_record/serialized/query_methods'

      include Base

      def read(locale, options = {})
        translations[locale]
      end

      def write(locale, value, options = {})
        translations[locale] = value
      end

      def self.configure!(options)
        options[:format] ||= :yaml
        options[:format] = options[:format].downcase.to_sym
        raise ArgumentError, "Serialized backend only supports yaml or json formats." unless [:yaml, :json].include?(options[:format])
      end

      setup do |attributes, options|
        coder = { yaml: YAMLCoder, json: JSONCoder }[options[:format]]
        attributes.each { |attribute| serialize attribute, coder }

        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend extension
      end

      def translations
        model.read_attribute(attribute)
      end
      alias_method :new_cache, :translations

      def write_to_cache?
        true
      end

      %w[yaml json].each do |format|
        class_eval <<-EOM, __FILE__, __LINE__ + 1
          class #{format.upcase}Coder
            def self.dump(obj)
              Serialized.serializer_for(:#{format}).call(obj)
            end

            def self.load(obj)
              return {} if obj.nil?
              Serialized.deserializer_for(:#{format}).call(obj)
            end
          end
        EOM
      end
    end
  end
end
