module Mobility
  module Backend
    class ActiveRecord::HashBackend
      def read(locale, **options)
        translations[locale]
      end

      def write(locale, value, **options)
        translations[locale] = value
      end

      def translations
        model.read_attribute(attribute)
      end
      alias_method :new_cache, :translations

      def write_to_cache?
        true
      end

      module Setup
        def setup_model(model_class, attributes, **options)
          super
          model_class.class_eval do
            attributes.each { |attribute| store attribute, coder: Coder }
            before_validation do
              attributes.each { |attribute| self.send(:"#{attribute}=", {}) if send(attribute).nil? }
            end
          end
        end
      end

      def self.inherited(backend_class)
        backend_class.include Backend
        backend_class.extend Setup
      end

      class Coder
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
    end
  end
end
