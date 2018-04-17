# frozen_string_literal: true
require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Container::JsonQueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods
      attr_reader :column_name, :column

      def initialize(_attributes, options)
        super
        @column = arel_table[options[:column_name]]
      end

      def matches(key, locale)
        build_infix(:'->>', build_infix(:'->', column, build_quoted(locale)), build_quoted(key))
      end

      def exists(key, locale)
        matches(key, locale).eq(nil).not
      end

      def absent(key, locale)
        matches(key, locale).eq(nil)
      end

      def quote(value)
        value.to_s
      end
    end
  end
end
