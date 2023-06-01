# frozen_string_literal: true
require 'mobility/backends/sequel/db_hash'

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Json} backend for Sequel models.

@see Mobility::Backends::HashValued

=end
    module Sequel
      class Json < DbHash
        # @!group Backend Accessors
        #
        # @!method read(locale, options = {})
        #   @note Translation may be any json type, but querying will only work on
        #     string-typed values.
        #   @param [Symbol] locale Locale to read
        #   @param [Hash] options
        #   @return [String,Integer,Boolean] Value of translation

        # @!method write(locale, value, options = {})
        #   @note Translation may be any json type, but querying will only work
        #     on string-typed values.
        #   @param [Symbol] locale Locale to write
        #   @param [String,Integer,Boolean] value Value to write
        #   @param [Hash] options
        #   @return [String,Integer,Boolean] Updated value
        # @!endgroup

        # @param [Symbol] name Attribute name
        # @param [Symbol] locale Locale
        # @return [Mobility::Backends::Sequel::Json::JSONOp]
        def self.build_op(attr, locale)
          column_name = column_affix % attr
          JSONOp.new(column_name.to_sym).get_text(locale.to_s)
        end

        class JSONOp < ::Sequel::Postgres::JSONOp; end
      end
    end

    register_backend(:sequel_json, Sequel::Json)
  end
end
