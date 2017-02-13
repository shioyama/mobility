module Mobility
  module Backend
=begin

Stores attribute translation as rows on a model-specific translation table
(similar to Globalize[https://github.com/globalize/globalize]). By default,
the table name for a model +Post+ with table +posts+ will be
+post_translations+, and the translation class will be +Post::Translation+. The
translation class is dynamically created when the backend is initialized on the
model class, and subclasses {Mobility::ActiveRecord::ModelTranslation} (for AR
models) or inherits {Mobility::Sequel::ModelTranslation} (for Sequel models).

The backend expects the translations table (+post_translations+) to have:

- a string column named +locale+ to store the locale of the translation
- columns for each translated attribute that uses the table (in general, this
  will be all attributes of the model)
- an integer column with name +post_id+ (where +post+ is the name of the model class)

Unlike Globalize, attributes need not all be on one table. Mobility supports
any number of translation tables for a given model class (all of the structure
described above), provided the +association_name+ option is different for each.
Some translations can be stored on one translation table, others on
another, and Mobility will handle mapping reads/writes to each. The subclass
used in this case will be generated from the +association_name+ by
singularizing it and converting it to camelcase.

For more details, see examples in {Mobility::Backend::ActiveRecord::Table}.

==Backend Options

===+association_name+

Name of association on model. Defaults to +:mobility_model_translations+. If
specified, ensure name does not overlap with other methods on model or with the
association name used by other backends on model (otherwise one will overwrite
the other).

===+table_name+

Name of translations table. By default, if the table used by the model is
+posts+, the table name used for translations will be +post_translations+.

===+foreign_key+

Foreign key to use in defining the association on the model. By default, if the
model is a +Post+, this will be +post_id+. Generally this does not need to be
set.

===+subclass_name+

Subclass to use when dynamically generating translation class for model, by
default +:Translation+. Should be a symbol. Generally this does not need to be
set.

@see Mobility::Backend::ActiveRecord::Table
@see Mobility::Backend::Sequel::Table
=end
    module Table
      include OrmDelegator

      # Simple hash cache to memoize translations as a hash so they can be
      # fetched quickly.
      class TranslationsCache < Hash

        # @yield [locale] Yields locale to block in case attribute is not yet
        #   cached, expects a new translation for that locale.
        # @raise [ArgumentError] if block is not given
        def initialize
          raise ArgumentError, "missing block" unless block_given?
          super() { |hash, locale| hash[locale] = yield(locale) }
        end

        # Return wrapper class which reads and writes to only one attribute of this cache.
        # @param [String] attribute
        # @return [Class] Hash-like wrapper object to be used as attribute cache
        def for(attribute)
          cache = self

          Class.new do
            define_singleton_method :[] do |locale|
              cache[locale].send(attribute)
            end

            define_singleton_method :[]= do |locale, value|
              cache[locale].send("#{attribute}=", value)
            end
          end
        end
      end
    end
  end
end
