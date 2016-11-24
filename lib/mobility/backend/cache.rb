module Mobility
  module Backend
    module Cache
      def read(locale, options = {})
        if cache.has_key?(locale)
          cache[locale]
        else
          super.tap { |value| cache[locale] = value }
        end
      end

      def write(locale, value, options = {})
        if cache[locale].respond_to?(:write)
          cache[locale].write(value)
        else
          cache[locale] = super
        end
        cache[locale]
      end

      module Setup
        def setup_model(model_class, attributes, options = {})
          super
          model_class.include BackendResetter.new(:clear_cache, attributes)
        end
      end

      def self.included(backend_class)
        backend_class.extend(Setup)
      end

      def clear_cache
        @cache = {}
      end

      private

      def cache
        @cache ||= {}
      end
    end
  end
end
