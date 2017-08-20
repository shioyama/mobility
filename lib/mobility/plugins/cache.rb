require "mobility/plugins/cache/translation_cacher"

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
      # Applies cache plugin to attributes.
      # @param [Attributes] attributes
      # @param [Boolean] option
      def self.apply(attributes, option)
        if option
          backend_class = attributes.backend_class
          backend_class.include(self) unless backend_class.apply_plugin(:cache)

          model_class = attributes.model_class
          model_class.include BackendResetter.for(model_class).new(attributes.names) { clear_cache }
        end
      end

      # @group Backend Accessors
      #
      # @!macro backend_reader
      # @option options [Boolean] cache
      #   *false* to disable cache.
      # @!method read(locale, value, options = {})
      include TranslationCacher.new(:read)

      # @!macro backend_writer
      # @option options [Boolean] cache
      #   *false* to disable cache.
      def write(locale, value, **options)
        return super if (options.delete(:cache) == false) || options[:super]
        cache[locale] = super
      end
      # @!endgroup
    end
  end
end
