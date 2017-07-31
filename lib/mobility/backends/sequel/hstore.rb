require 'mobility/backends/sequel/pg_hash'

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Hstore} backend for Sequel models.

@see Mobility::Backends::Sequel::HashValued

=end
    class Sequel::Hstore < Sequel::PgHash
      require 'mobility/backends/sequel/hstore/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, options = {})
        super(locale, value && value.to_s, options)
      end
      # @!endgroup

      setup_query_methods(QueryMethods)
    end
  end
end
