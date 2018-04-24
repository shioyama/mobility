# frozen_string_literal: true
require 'mobility/backends/active_record/pg_query_methods'
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    module ActiveRecord
      class Json::QueryMethods < QueryMethods
        include PgQueryMethods

        def matches(key, locale)
          build_infix(:'->>', arel_table[column_name(key)], build_quoted(locale))
        end

        def exists(key, locale)
          absent(key, locale).not
        end

        def absent(key, locale)
          matches(key, locale).eq(nil)
        end

        def quote(value)
          value.to_s
        end
      end
      Json.private_constant :QueryMethods
    end
  end
end
