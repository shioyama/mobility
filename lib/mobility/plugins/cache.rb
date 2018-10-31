# frozen_string_literal: true

module Mobility
  module Plugins
=begin

Caches values fetched from the backend so subsequent fetches can be performed
more quickly. The cache stores cached values in a simple hash, which is not
optimal for some storage strategies, so some backends (KeyValue, Table) use a
custom module through the {Mobility::Backend::Setup#apply_plugin} hook. For
details see the documentation for these backends.

The cache is reset when one of a set of events happens (saving, reloading,
etc.). See {BackendResetter} for details.

Values are added to the cache in two ways:

1. first read from backend
2. any write to backend

=end
    module Cache
      extend Plugin

      # Applies cache plugin to attributes.
      included_hook do |model_class, backend_class|
        if options[:cache]
          backend_class.include(BackendMethods) unless backend_class.apply_plugin(:cache)
          model_class.include BackendResetter.for(model_class).new(names) { clear_cache }
        end
      end

      module BackendMethods
        # @group Backend Accessors
        #
        # @!macro backend_reader
        # @!method read(locale, value, options = {})
        #   @option options [Boolean] cache *false* to disable cache.
        def read(locale, **options)
          return super(locale, options) if options.delete(:cache) == false
          if cache.has_key?(locale)
            cache[locale]
          else
            cache[locale] = super(locale, options)
          end
        end

        # @!macro backend_writer
        # @option options [Boolean] cache
        #   *false* to disable cache.
        def write(locale, value, **options)
          return super if options.delete(:cache) == false
          cache[locale] = super
        end
        # @!endgroup

        private

        def cache
          @cache ||= {}
        end

        def clear_cache
          @cache = {}
        end
      end
    end
  end
end
