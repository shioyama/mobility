# frozen_string_literal: true
require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Json::QueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods

      def matches(key, value, locale)
        build_locale_infix(key, locale).eq(value.to_s)
      end

      def has_locale(key, locale)
        build_locale_infix(key, locale).eq(nil).not
      end

      private

      def build_locale_infix(key, locale)
        build_infix(:'->>', arel_table[column_name(key)], quote(locale))
      end
    end
  end
end
