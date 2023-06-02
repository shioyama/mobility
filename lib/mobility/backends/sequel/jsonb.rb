# frozen_string_literal: true
require 'mobility/backends/sequel/db_hash'

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Jsonb} backend for Sequel models.

@see Mobility::Backends::HashValued

=end
    module Sequel
      class Jsonb < DbHash
        # @!group Backend Accessors
        #
        # @!method read(locale, **options)
        #   @note Translation may be string, integer or boolean-valued since
        #     value is stored on a JSON hash.
        #   @param [Symbol] locale Locale to read
        #   @param [Hash] options
        #   @return [String,Integer,Boolean] Value of translation
        #
        # @!method write(locale, value, **options)
        #   @note Translation may be string, integer or boolean-valued since
        #     value is stored on a JSON hash.
        #   @param [Symbol] locale Locale to write
        #   @param [String,Integer,Boolean] value Value to write
        #   @param [Hash] options
        #   @return [String,Integer,Boolean] Updated value
        # @!endgroup

        # @param [Symbol] name Attribute name
        # @param [Symbol] locale Locale
        # @return [Mobility::Backends::Sequel::Jsonb::JSONBOp]
        def self.build_op(attr, locale)
          column_name = column_affix % attr
          JSONBOp.new(column_name.to_sym).get_text(locale.to_s)
        end

        class JSONBOp < ::Sequel::Postgres::JSONBOp
          def to_dash_arrow
            column = @value.args[0].value
            locale = @value.args[1]
            ::Sequel.pg_jsonb_op(column)[locale]
          end

          def to_question
            column = @value.args[0].value
            locale = @value.args[1]
            ::Sequel.pg_jsonb_op(column).has_key?(locale)
          end

          def =~(other)
            case other
            when Integer, ::Hash
              to_dash_arrow =~ other.to_json
            when NilClass
              ~to_question
            else
              super
            end
          end
        end
      end
    end

    register_backend(:sequel_jsonb, Sequel::Jsonb)
  end
end
