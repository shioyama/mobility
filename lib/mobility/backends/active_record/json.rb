require 'mobility/backends/active_record/pg_hash'

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Json} backend for ActiveRecord models.

@see Mobility::Backends::ActiveRecord::HashValued

=end
    module ActiveRecord
      class Json < PgHash
        require 'mobility/backends/active_record/json/query_methods'

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

        setup_query_methods(QueryMethods)
      end
    end
  end
end
