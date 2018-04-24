# frozen_string_literal: true
require "mobility/backends/sequel/pg_query_methods"
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    module Sequel
      class Container::JsonQueryMethods < QueryMethods
        include PgQueryMethods
        attr_reader :column_name

        def initialize(attributes, options)
          super
          @column_name = options[:column_name]
          define_query_methods
        end

        def matches(key, locale)
          build_op(column_name)[locale].get_text(key.to_s)
        end

        def exists(key, locale)
          matches(key, locale) !~ nil
        end

        def quote(value)
          value && value.to_s
        end

        private

        def build_op(key)
          ::Sequel.pg_json_op(key)
        end
      end
      Container.private_constant :JsonQueryMethods
    end
  end
end
