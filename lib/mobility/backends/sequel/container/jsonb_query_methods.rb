# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Container::JsonbQueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods
      attr_reader :column_name

      def initialize(attributes, options)
        super
        @column_name = options[:column_name]
        define_query_methods
      end

      def matches(key, locale)
        build_op(column_name)[locale][key.to_s]
      end

      def exists(key, locale)
        build_op(column_name).has_key?(locale) & build_op(column_name)[locale].has_key?(key.to_s)
      end

      def quote(value)
        value && value.to_json
      end

      private

      def build_op(key)
        ::Sequel.pg_jsonb_op(key)
      end
    end
  end
end
