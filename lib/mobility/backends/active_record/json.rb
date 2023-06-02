require 'mobility/backends/active_record/db_hash'
require 'mobility/plugins/arel/nodes/json_ops'

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Json} backend for ActiveRecord models.

@see Mobility::Backends::HashValued

=end
    module ActiveRecord
      class Json < DbHash
        # @!group Backend Accessors
        #
        # @!method read(locale, **options)
        #   @note Translation may be string, integer or boolean-valued since
        #     value is stored on a JSON hash.
        #   @param [Symbol] locale Locale to read
        #   @param [Hash] options
        #   @return [String,Integer,Boolean] Value of translation

        # @!method write(locale, value, **options)
        #   @note Translation may be string, integer or boolean-valued since
        #     value is stored on a JSON hash.
        #   @param [Symbol] locale Locale to write
        #   @param [String,Integer,Boolean] value Value to write
        #   @param [Hash] options
        #   @return [String,Integer,Boolean] Updated value
        # @!endgroup

        # @param [String] attr Attribute name
        # @param [Symbol] locale Locale
        # @return [Mobility::Plugins::Arel::Nodes::Json] Arel node for value of
        #   attribute key on jsonb column
        def self.build_node(attr, locale)
          column_name = column_affix % attr
          Plugins::Arel::Nodes::Json.new(model_class.arel_table[column_name], build_quoted(locale))
        end
      end
    end

    register_backend(:active_record_json, ActiveRecord::Json)
  end
end
