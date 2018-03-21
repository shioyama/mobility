# frozen_string_literal: true
require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Jsonb::QueryMethods < ActiveRecord::QueryMethods
      include ActiveRecord::PgQueryMethods

      def matches(key, value, locale)
        build_infix(:'->', arel_table[key], quote(locale)).eq(quote(value.to_json))
      end

      def has_locale(key, locale)
        build_infix(:'?', arel_table[key], quote(locale))
      end
    end
  end
end
