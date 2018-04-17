# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Json::QueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods

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
  end
end
