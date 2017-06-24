require 'mobility/backend/sequel/postgres_query_methods'

Sequel.extension :pg_hstore, :pg_hstore_ops

module Mobility
  module Backend
    class Sequel::Hstore::QueryMethods < Sequel::QueryMethods
      include PostgresQueryMethods

      def initialize(attributes, **)
        super

        define_query_methods("hstore")

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(::Sequel.hstore(attribute.to_sym).contains(::Sequel.hstore({ Mobility.locale.to_s => value }))).
              select_all(model.table_name).first
          end
        end
      end
    end
  end
end
