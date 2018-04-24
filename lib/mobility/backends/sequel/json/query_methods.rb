# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    module Sequel
      class Json::QueryMethods < QueryMethods
        include PgQueryMethods

        def matches(key, locale)
          build_op(key).get_text(locale)
        end

        def exists(key, locale)
          matches(key, locale) !~ nil
        end

        def quote(value)
          value && value.to_s
        end

        private

        def build_op(key)
          ::Sequel.pg_json_op(column_name(key))
        end
      end
      Json.private_constant :QueryMethods
    end
  end
end
