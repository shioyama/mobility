require 'mobility/backends/active_record/pg_query_methods'
require 'mobility/backends/active_record/query_methods'

module Mobility
  module Backends
    class ActiveRecord::Hstore::QueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods

      private

      def contains_value(column, value, locale)
        build_infix(:'->', column, quote(locale)).eq(quote(value.to_s))
      end
    end
  end
end
