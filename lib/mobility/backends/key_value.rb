# frozen_string_literal: true
require "mobility/plugins/cache"

module Mobility
  module Backends
=begin

Stores attribute translation as attribute/value pair on a shared translations
table, using a polymorphic relationship between a translation class and models
using the backend. By default, two tables are assumed to be present supporting
string and text translations: a +mobility_text_translations+ table for
text-valued translations and a +string_translations+ table for
string-valued translations (the only difference being the column type of the
+value+ column on the table).

==Backend Options

===+type+

Currently, either +:text+ or +:string+ is supported, but any value is allowed
as long as a corresponding +class_name+ can be found (see below). Determines
which class to use for translations, which in turn determines which table to
use to store translations (by default +text_translations+ for text type,
+string_translations+ for string type).

===+class_name+

Class to use for translations when defining association. By default,
{Mobility::ActiveRecord::TextTranslation} or
{Mobility::ActiveRecord::StringTranslation} for ActiveRecord models (similar
for Sequel models). If string is passed in, it will be constantized to get the
class.

===+association_name+

Name of association on model. Defaults to +<type>_translations+, which will
typically be either +:text_translations+ (if +type+ is +:text+) or
+:string_translations (if +type+ is +:string+). If specified, ensure name does
not overlap with other methods on model or with the association name used by
other backends on model (otherwise one will overwrite the other).

@see Mobility::Backends::ActiveRecord::KeyValue
@see Mobility::Backends::Sequel::KeyValue

=end
    module KeyValue
      extend Backend::OrmDelegator

      # @!method association_name
      #   Returns the name of the polymorphic association.
      #   @return [Symbol] Name of the association

      # @!method class_name
      #   Returns translation class used in polymorphic association.
      #   @return [Class] Translation class

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, options = {})
        translation_for(locale, **options).value
      end

      # @!macro backend_writer
      def write(locale, value, options = {})
        translation_for(locale, **options).value = value
      end
      # @!endgroup

      # @!macro backend_iterator
      def each_locale
        translations.each { |t| yield(t.locale.to_sym) if t.key == attribute }
      end

      private

      def translations
        model.send(association_name)
      end

      def self.included(backend_class)
        backend_class.extend ClassMethods
        backend_class.option_reader :association_name
        backend_class.option_reader :class_name
        backend_class.option_reader :table_alias_affix
      end

      module ClassMethods
        # @!group Backend Configuration
        # @option options [Symbol,String] type Column type to use
        # @option options [Symbol] associaiton_name (:<type>_translations) Name
        #   of association method, defaults to +<type>_translations+
        # @option options [Symbol] class_name Translation class, defaults to
        #   +Mobility::<ORM>::<type>Translation+
        # @raise [ArgumentError] if +type+ is not set, and both +class_name+
        #   and +association_name+ are also not set
        def configure(options)
          options[:type]             &&= options[:type].to_sym
          options[:association_name] &&= options[:association_name].to_sym
          options[:class_name]       &&= Util.constantize(options[:class_name])
          if !(options[:type] || (options[:class_name] && options[:association_name]))
            raise ArgumentError, "KeyValue backend requires an explicit type option, either text or string."
          end
        end

        # Apply custom processing for plugin
        # @param (see Backend::Setup#apply_plugin)
        # @return (see Backend::Setup#apply_plugin)
        def apply_plugin(name)
          if name == :cache
            include self::Cache
            true
          else
            super
          end
        end

        def table_alias(attr, locale)
          table_alias_affix % "#{attr}_#{Mobility.normalize_locale(locale)}"
        end
      end

      module Cache
        def translation_for(locale, **options)
          return super(locale, options) if options.delete(:cache) == false
          if cache.has_key?(locale)
            cache[locale]
          else
            cache[locale] = super(locale, **options)
          end
        end

        def clear_cache
          @cache = {}
        end

        private

        def cache
          @cache ||= {}
        end
      end
    end
  end
end
