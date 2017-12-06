require 'mobility/backends/sequel/pg_query_methods'
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backends
    class Sequel::Jsonb::QueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods

      def initialize(attributes, _)
        super

        define_query_methods

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(::Sequel.pg_jsonb_op(attribute).contains({ Mobility.locale => value })).
              select_all(model.table_name).first
          end
        end
      end

      private

      def build_pg_op(v)
        ::Sequel.pg_jsonb_op(v)
      end
    end
  end
end
