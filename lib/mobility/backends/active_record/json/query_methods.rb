# frozen_string_literal: true
require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Json::QueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods

      private

      def matches(key, value, locale)
        build_locale_infix(key, locale).eq(value.to_s)
      end

      def has_locale(key, locale)
        build_locale_infix(key, locale).eq(nil).not
      end

      def build_locale_infix(key, locale)
        arel_table.grouping(build_infix(:'->>', arel_table[key], quote(locale)))
      end
    end
  end
end
