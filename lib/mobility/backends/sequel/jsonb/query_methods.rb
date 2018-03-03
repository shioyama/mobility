# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Jsonb::QueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods

      private

      def matches(key, value, locale)
        build_op(key)[locale] =~ value.to_json
      end

      def has_locale(key, locale)
        build_op(key).has_key?(locale)
      end

      def build_op(key)
        ::Sequel.pg_jsonb_op(key)
      end
    end
  end
end
