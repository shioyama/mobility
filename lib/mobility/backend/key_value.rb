module Mobility
  module Backend
    module KeyValue
      include OrmDelegator

      class TranslationsCache
        def initialize(backend)
          @cache = Hash.new { |hash, locale| hash[locale] = backend.translation_for(locale) }
        end

        def [](locale)
          @cache[locale].value
        end

        def []=(locale, value)
          @cache[locale].value = value
        end

        def each_translation &block
          @cache.each_value &block
        end
      end
    end
  end
end
