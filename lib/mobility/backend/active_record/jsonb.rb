module Mobility
  module Backend
    class ActiveRecord::Jsonb
      include Backend

      autoload :QueryMethods, 'mobility/backend/active_record/jsonb/query_methods'

      def read(locale, **options)
        translations[locale]
      end

      def write(locale, value, **options)
        translations[locale] = value && value.to_s
      end

      def self.configure!(options)
        if options[:format].present?
          raise ArgumentError, "Format must be JSON for Jsonb backend." if options[:format].to_s != "json"
        else
          options[:format] = :json
        end
      end

      setup do |attributes, options|
        attributes.each { |attribute| store attribute, coder: JSONCoder }
        before_validation do
          attributes.each { |attribute| self.send(:"#{attribute}=", {}) if send(attribute).nil? }
        end
        query_methods = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend query_methods
      end

      class JSONCoder
        def self.dump(obj)
          if obj.is_a? Hash
            obj = obj.inject({}) do |translations, (locale, value)|
              translations[locale] = value if value.present?
              translations
            end
          else
            raise ArgumentError, "Attribute is supposed to be a Hash, but was a #{obj.class}. -- #{obj.inspect}"
          end
        end

        def self.load(obj)
          obj
        end
      end

      def translations
        model.read_attribute(attribute)
      end
      alias_method :new_cache, :translations

      def write_to_cache?
        true
      end
    end
  end
end
