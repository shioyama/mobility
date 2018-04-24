# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    module Sequel
      class Jsonb::QueryMethods < QueryMethods
        include PgQueryMethods

        def matches(key, locale)
          build_op(key)[locale]
        end

        def exists(key, locale)
          build_op(key).has_key?(locale)
        end

        def quote(value)
          value && value.to_json
        end

        private

        def build_op(key)
          ::Sequel.pg_jsonb_op(column_name(key))
        end
      end
      Jsonb.private_constant :QueryMethods
    end
  end
end
