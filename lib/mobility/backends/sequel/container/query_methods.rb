require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Container::QueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods
      attr_reader :column_name

      def initialize(attributes, options)
        super
        @column_name = options[:column_name]
        define_query_methods
      end

      private

      def matches(key, value, locale)
        build_op(column_name)[locale][key.to_s] =~ value.to_json
      end

      def has_locale(key, locale)
        build_op(column_name).has_key?(locale) & build_op(column_name)[locale].has_key?(key.to_s)
      end

      def build_op(key)
        ::Sequel.pg_jsonb_op(key)
      end
    end
  end
end
