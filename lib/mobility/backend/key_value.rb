module Mobility
  module Backend
=begin

Stores attribute translation as attribute/value pair on a shared translations
table, using a polymorphic relationship between a translation class and models
using the backend. By default, two tables are assumed to be present supporting
string and text translations: a +mobility_text_translations+ table for text-valued translations and a
+mobility_string_translations+ table for string-valued translations (the only
difference being the column type of the +value+ column on the table).

==Backend Options

===+association_name+

Name of association on model. Defaults to +mobility_text_translations+ (if
+type+ is +:text+) or +mobility_string_translations+ (if +type+ is +:string+).
If specified, ensure name does not overlap with other methods on model or with
the association name used by other backends on model (otherwise one will
overwrite the other).

===+type+

Currently, either +:text+ or +:string+ is supported. Determines which class to
use for translations, which in turn determines which table to use to store
translations (by default +mobility_text_translations+ for text type,
+mobility_string_translations+ for string type).

===+class_name+

Class to use for translations when defining association. By default,
{Mobility::ActiveRecord::TextTranslation} or
{Mobility::ActiveRecord::StringTranslation} for ActiveRecord models (similar
for Sequel models). If string is passed in, it will be constantized to get the
class.

@see Mobility::Backend::ActiveRecord::KeyValue
@see Mobility::Backend::Sequel::KeyValue

=end
    module KeyValue
      extend OrmDelegator

      def self.included(backend)
        backend.extend ClassMethods
      end

      module ClassMethods
        # @!group Backend Configuration
        # @option options [Symbol,String] type (:text) Column type to use
        # @raise [ArgumentError] if type is not either :text or :string
        def configure(options)
          options[:type] = (options[:type] || :text).to_sym
          raise ArgumentError, "type must be one of: [text, string]" unless [:text, :string].include?(options[:type])
        end

        # Apply custom processing for option module
        # @param (see Backend::Setup#apply_module)
        def apply_module(name)
          if name == :cache
            include TranslationCacher.new(:translation_for)
            true
          else
            super
          end
        end
      end
    end
  end
end
