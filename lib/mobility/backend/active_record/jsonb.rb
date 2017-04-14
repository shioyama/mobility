require 'mobility/backend/active_record/hash_valued'

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Jsonb} backend for ActiveRecord models.

@see Mobility::Backend::ActiveRecord::HashValued

=end
    class ActiveRecord::Jsonb < ActiveRecord::HashValued
      require 'mobility/backend/active_record/jsonb/query_methods'

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

      setup_query_methods(QueryMethods)
    end
  end
end
