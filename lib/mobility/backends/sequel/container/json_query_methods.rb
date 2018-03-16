# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Container::JsonQueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods
      attr_reader :column_name

      def initialize(attributes, options)
        super
        @column_name = options[:column_name]
        define_query_methods
      end

      private

      def matches(key, value, locale)
        build_op(column_name)[locale].get_text(key.to_s) =~ value.to_s
      end

      def has_locale(key, locale)
        build_op(column_name)[locale].get_text(key.to_s) !~ nil
      end

      def build_op(key)
        ::Sequel.pg_json_op(key)
      end
    end
  end
end
