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
          class_eval <<-EOM, __FILE__, __LINE__ + 1
            def #{fetch_method} locale, **options
              return super(locale, options) if options.delete(:cache) == false
              if cache.has_key?(locale)
                cache[locale]
              else
                cache[locale] = super(locale, options)
              end
            end
          EOM

          include CacheMethods
        end

        module CacheMethods
          private
          def cache;       @cache ||= {}; end
          def clear_cache; @cache = {};   end
        end
      end
    end
  end
end
