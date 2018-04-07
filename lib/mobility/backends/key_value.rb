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

      # @return [Symbol] name of the association
      attr_reader :association_name

      # @!macro backend_constructor
      # @option options [Symbol] association_name Name of association
      def initialize(model, attribute, options = {})
        super
        @association_name = options[:association_name]
      end

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, options = {})
        translation_for(locale, options).value
      end

      # @!macro backend_reader
      def write(locale, value, options = {})
        translation_for(locale, options).value = value
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

      def self.included(backend)
        backend.extend ClassMethods
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
            # TODO: Remove warning and raise ArgumentError in v1.0
            warn %{
WARNING: In previous versions, the Mobility KeyValue backend defaulted to a
text type column, but this behavior is now deprecated and will be removed in
the next release. Either explicitly specify the type by passing type: :text in
each translated model, or set a default option in your configuration.
  }
            options[:type] = :text
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
      end

      module Cache
        include Plugins::Cache::TranslationCacher.new(:translation_for)
      end
    end
  end
end
