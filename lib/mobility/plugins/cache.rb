# frozen_string_literal: true

module Mobility
  module Plugins
=begin

Caches values fetched from the backend so subsequent fetches can be performed
more quickly. The cache stores cached values in a simple hash, which is not
optimal for some storage strategies, so some backends (KeyValue, Table) use a
custom module by defining a method, +include_cache+, on the backend class.

The cache is reset when one of a set of events happens (saving, reloading,
etc.). See {BackendResetter} for details.

Values are added to the cache in two ways:

1. first read from backend
2. any write to backend

=end
    module Cache
      extend Plugin

      default true
      requires :backend, include: :before

      # Applies cache plugin to attributes.
      included_hook do |_, backend_class|
        if options[:cache]
          if backend_class.respond_to?(:include_cache)
            backend_class.include_cache
          else
            include_cache(backend_class)
          end
        end
      end

      private

      def include_cache(backend_class)
        backend_class.include BackendMethods
      end

      # Used in ORM cache plugins
      def define_cache_hooks(klass, *reset_methods)
        mod = self
        private_methods = reset_methods & klass.private_instance_methods
        reset_methods.each do |method_name|
          define_method method_name do |*args|
            super(*args).tap do
              mod.names.each { |name| mobility_backends[name].clear_cache }
            end
          end
        end
        klass.class_eval { private(*private_methods) }
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

        def clear_cache
          @cache = {}
        end

        private

        def cache
          @cache ||= {}
        end
      end
    end

    register_plugin(:cache, Cache)
  end
end
