require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Jsonb::QueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods

      private

      def contains_value(column, value)
        build_infix(:'@>', column, Arel::Nodes.build_quoted({ Mobility.locale => value }.to_json))
      end
    end
  end
end
