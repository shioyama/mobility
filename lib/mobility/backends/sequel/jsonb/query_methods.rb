require 'mobility/backends/sequel/postgres_query_methods'
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Jsonb::QueryMethods < Sequel::QueryMethods
      include PostgresQueryMethods

      def initialize(attributes, _)
        super

        define_query_methods("pg_jsonb")

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(::Sequel.pg_jsonb_op(attribute).contains({ Mobility.locale => value })).
              select_all(model.table_name).first
          end
        end
      end
    end
  end
end
