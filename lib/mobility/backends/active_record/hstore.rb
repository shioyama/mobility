require 'mobility/backends/active_record/pg_hash'

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Hstore} backend for ActiveRecord models.

@see Mobility::Backends::ActiveRecord::HashValued

=end
    module ActiveRecord
      class Hstore < PgHash
        require 'mobility/backends/active_record/hstore/query_methods'

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
end
