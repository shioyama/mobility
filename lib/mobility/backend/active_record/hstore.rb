require 'mobility/backend/active_record/pg_hash'

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Hstore} backend for ActiveRecord models.

@see Mobility::Backend::ActiveRecord::HashValued

=end
    class ActiveRecord::Hstore < ActiveRecord::PgHash
      require 'mobility/backend/active_record/hstore/query_methods'

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
