require 'mobility/backends/sequel/pg_hash'

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Json} backend for Sequel models.

@see Mobility::Backends::Sequel::HashValued

=end
    class Sequel::Json < Sequel::PgHash
      require 'mobility/backends/sequel/json/query_methods'

      # @!group Backend Accessors
      #
      # @note Translation may be any json type, but querying will only work on
      #   string-typed values.
      # @param [Symbol] locale Locale to read
      # @param [Hash] options
      # @return [String,Integer,Boolean] Value of translation
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @note Translation may be any json type, but querying will only work on
      #   string-typed values.
      # @param [Symbol] locale Locale to write
      # @param [String,Integer,Boolean] value Value to write
      # @param [Hash] options
      # @return [String,Integer,Boolean] Updated value
      # @!method write(locale, value, **options)

      setup_query_methods(QueryMethods)
    end
  end
end
