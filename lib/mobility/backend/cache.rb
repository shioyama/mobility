module Mobility
  module Backend
=begin

Caches values fetched from the backend so subsequent fetches can be performed
more quickly.

By default, the cache stores cached values in a simple hash, returned from the
{new_cache} method added to the including backend instance class. To use a
different cache class, simply define a +new_cache+ method in the backend and
return a new instance of the cache class (many backends do this, see
{Mobility::Backend::KeyValue} for one example.)

The cache is reset by the {clear_cache} method, which by default simply assigns
the result of {new_cache} to the +@cache+ instance variable. This behaviour can
also be customized by defining a +new_cache+ method on the backend class (see
{Mobility::Backend::ActiveRecord::Table#new_cache} for an example of a backend that does this).

The cache is reset when one of a set of events happens (saving, reloading,
etc.). See {BackendResetter} for details.

Values are added to the cache in two ways:

1. first read from backend
2. any write to backend

The latter can be customized by defining the {write_to_cache?} method, which by
default returns +false+. If set to +true+, then writes will only update the
cache and not hit the backend. This is a sensible setting in case the cache is
actually an object which directly stores the translation (see one of the
ORM-specific implementations of {Mobility::Backend::KeyValue} for examples of
this).

=end
    module Cache
      # @group Backend Accessors
      # @!macro backend_reader
      def read(locale, **options)
        if write_to_cache? || cache.has_key?(locale)
          cache[locale]
        else
          cache[locale] = super
        end
      end

      # @!macro backend_writer
      def write(locale, value, **options)
        cache[locale] = write_to_cache? ? value : super
      end
      # @!endgroup

      # Adds hook to {Backend::Setup#setup_model} to include instance of
      # model-specific {BackendResetter} subclass when setting up
      # model class, to trigger cache resetting at specific events (saving,
      # reloading, etc.)
      module Setup
        # @param model_class Model class
        # @param [Array<String>] attributes Backend attributes
        # @param [Hash] options Backend options
        def setup_model(model_class, attributes, **options)
          super
          model_class.include BackendResetter.for(model_class).new(:clear_cache, attributes)
        end
      end

      # @!group Cache Methods
      # @!parse
      #   def new_cache
      #     {}
      #   end
      #
      # @!parse
      #   def write_to_cache?
      #     false
      #   end
      #
      # @!parse
      #   def clear_cache
      #     @cache = new_cache
      #   end
      # @!endgroup

      # Includes cache methods to backend (unless they are already defined) and
      # extends backend class with {Mobility::Cache::Setup} for backend resetting.
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
