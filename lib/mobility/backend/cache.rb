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
