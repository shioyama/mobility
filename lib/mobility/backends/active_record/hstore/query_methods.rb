require 'mobility/backends/active_record/pg_query_methods'
require 'mobility/backends/active_record/query_methods'

module Mobility
  module Backends
    class ActiveRecord::Hstore::QueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods

      def matches(key, value, locale)
        build_infix(:'->', arel_table[column_name(key)], quote(locale)).eq(quote(value.to_s))
      end

      def has_locale(key, locale)
        build_infix(:'?', arel_table[column_name(key)], quote(locale))
      end
    end
  end
end
