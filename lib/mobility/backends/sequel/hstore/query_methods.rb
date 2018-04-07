# frozen_string_literal: true
require 'mobility/backends/sequel/pg_query_methods'
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_hstore, :pg_hstore_ops

module Mobility
  module Backends
    class Sequel::Hstore::QueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods

      def matches(key, value, locale)
        build_op(key)[locale] =~ value.to_s
      end

      def has_locale(key, locale)
        build_op(key).has_key?(locale)
      end

      private

      def build_op(key)
        ::Sequel.hstore_op(column_name(key))
      end
    end
  end
end
