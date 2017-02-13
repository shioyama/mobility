require 'mobility/backend/sequel/hash_valued'

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Jsonb} backend for Sequel models.

@see Mobility::Backend::Sequel::HashValued

=end
    class Sequel::Jsonb < Sequel::HashValued
      autoload :QueryMethods, 'mobility/backend/sequel/jsonb/query_methods'

      # @!group Backend Accessors
      #
      # @note Translation may be string, integer or boolean-valued since
      #   value is stored on a JSON hash.
      # @param [Symbol] locale Locale to read
      # @param [Hash] options
      # @return [String,Integer,Boolean] Value of translation
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @note Translation may be string, integer or boolean-valued since
      #   value is stored on a JSON hash.
      # @param [Symbol] locale Locale to write
      # @param [String,Integer,Boolean] value Value to write
      # @param [Hash] options
      # @return [String,Integer,Boolean] Updated value
      # @!method write(locale, value, **options)

      setup do |attributes, options|
        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension
      end
    end
  end
end
