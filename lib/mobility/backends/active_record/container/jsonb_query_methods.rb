# frozen_string_literal: true
require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Container::JsonbQueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods
      attr_reader :column_name, :column

      def initialize(_attributes, options)
        super
        @column_name = options[:column_name]
        @column      = arel_table[@column_name]
      end

      private

      def matches(key, value, locale)
        build_infix(:'->',
                    build_infix(:'->', column, quote(locale)),
                    quote(key)).eq(value && quote(value.to_json))
      end

      def has_locale(key, locale)
        matches(key, nil, locale).not
      end
    end
  end
end
