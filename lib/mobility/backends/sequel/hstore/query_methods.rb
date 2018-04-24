# frozen_string_literal: true
require 'mobility/backends/sequel/pg_query_methods'
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_hstore, :pg_hstore_ops

module Mobility
  module Backends
    module Sequel
      class Hstore::QueryMethods < QueryMethods
        include PgQueryMethods

        def matches(key, locale)
          build_op(key)[locale]
        end

        def exists(key, locale)
          build_op(key).has_key?(locale)
        end

        def quote(value)
          value && value.to_s
        end

        private

        def build_op(key)
          ::Sequel.hstore_op(column_name(key))
        end
      end
      Hstore.private_constant :QueryMethods
    end
  end
end
