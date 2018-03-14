# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Json::QueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods

      private

      def matches(key, value, locale)
        build_op(key).get_text(locale) =~ value.to_s
      end

      def has_locale(key, locale)
        build_op(key).get_text(locale) !~ nil
      end

      def build_op(key)
        ::Sequel.pg_json_op(key)
      end
    end
  end
end
