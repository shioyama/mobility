# frozen_string_literal: true
require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Container::JsonbQueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods
      attr_reader :column

      def initialize(_attributes, options)
        super
        @column = arel_table[options[:column_name]]
      end

      def matches(key, locale)
        build_infix(:'->', build_infix(:'->', column, build_quoted(locale)), build_quoted(key))
      end

      def exists(key, locale)
        build_infix(:'?', column, build_quoted(locale)).and(
          build_infix(:'?', build_infix(:'->', column, build_quoted(locale)), build_quoted(key)))
      end

      def quote(value)
        build_quoted(value.to_json)
      end
    end
  end
end
