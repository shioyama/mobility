module Mobility
  module Backend
    module Table
      include OrmDelegator

      class TranslationCache
        def initialize(backend)
          @cache   = {}
          @backend = backend
        end

        def has_key?(_)
          true
        end

        def cached_translation(locale)
          @cache[locale] ||= @backend.translation_for(locale)
        end

        def [](locale)
          cached_translation(locale).value
        end

        def []=(locale, value)
          cached_translation(locale).value = value
        end

        def each_translation &block
          @cache.each_value &block
        end
      end
    end
  end
end
