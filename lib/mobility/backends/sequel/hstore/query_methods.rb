require 'mobility/backends/sequel/pg_query_methods'
require "mobility/backends/sequel/query_methods"

Sequel.extension :pg_hstore, :pg_hstore_ops

module Mobility
  module Backends
    class Sequel::Hstore::QueryMethods < Sequel::QueryMethods
      include Sequel::PgQueryMethods

      def initialize(attributes, _)
        super

        define_query_methods

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(::Sequel.hstore(attribute.to_sym).contains(::Sequel.hstore({ Mobility.locale.to_s => value }))).
              select_all(model.table_name).first
          end
        end
      end

      private

      def contains_value(key, value, locale)
        build_op(key).contains(locale => value.to_s)
      end

      def has_locale(key, locale)
        build_op(key).has_key?(locale)
      end

      def build_op(key)
        ::Sequel.hstore_op(key)
      end
    end
  end
end
