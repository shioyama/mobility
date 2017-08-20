module Mobility
  module Plugins
    module Cache
=begin

Creates a module to cache a given translation fetch method. The cacher defines
private methods +cache+ and +clear_cache+ to access and clear, respectively, a
translations hash.

This cacher is used to cache translation values in {Mobility::Plugins::Cache},
and also to cache translation *records* in {Mobility::Backends::Table} and
{Mobility::Backends::KeyValue}.

=end
      class TranslationCacher < Module
        # @param [Symbol] fetch_method Name of translation fetch method to cache
        def initialize(fetch_method)
          define_method fetch_method do |locale, **options|
            return super(locale, options) if (options.delete(:cache) == false) || options[:super]

            if cache.has_key?(locale)
              cache[locale]
            else
              cache[locale] = super(locale, options)
            end
          end

          define_method :cache do
            @cache ||= {}
          end

          define_method :clear_cache do
            @cache = {}
          end

          private :cache, :clear_cache
        end
      end
    end
  end
end
