module Mobility
  module Backend
    module Cache
      def read(locale, **options)
        if write_to_cache? || cache.has_key?(locale)
          cache[locale]
        else
          cache[locale] = super
        end
      end

      def write(locale, value, **options)
        cache[locale] = write_to_cache? ? value : super
      end

      module Setup
        def setup_model(model_class, attributes, **options)
          super
          model_class.include BackendResetter.for(model_class).new(:clear_cache, attributes)
        end
      end

      def self.included(backend_class)
        backend_class.class_eval do
          extend Setup

          def new_cache
            {}
          end unless method_defined?(:new_cache)

          def write_to_cache?
            false
          end unless method_defined?(:write_to_cache?)

          def clear_cache
            @cache = new_cache
          end unless method_defined?(:clear_cache)
        end
      end

      private

      def cache
        @cache ||= new_cache
      end
    end
  end
end
