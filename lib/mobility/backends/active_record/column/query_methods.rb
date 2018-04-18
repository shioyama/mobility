# frozen_string_literal: true
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Column::QueryMethods < ActiveRecord::QueryMethods
      attr_reader :arel_table

      def initialize(attributes, options)
        super
        @arel_table = options[:model_class].arel_table

        q = self

        define_method :where! do |opts, *rest|
          if i18n_keys = q.extract_attributes(opts)
            opts = opts.with_indifferent_access
            query = q.create_query!(opts, i18n_keys, locale: opts.delete(:locale))

            opts.empty? ? super(query) : super(opts, *rest).where(query)
          else
            super(opts, *rest)
          end
        end
      end

      def extended(relation)
        super
        q = self

        mod = Module.new do
          define_method :not do |opts, *rest|
            if i18n_keys = q.extract_attributes(opts)
              opts = opts.with_indifferent_access
              query = q.create_query!(opts, i18n_keys, inverse: true, locale: opts.delete(:locale))

              opts.empty? ? super(query) : super(opts, *rest).where.not(query)
            else
              super(opts, *rest)
            end
          end
        end
        relation.mobility_where_chain.include(mod)
      end

      def create_query!(opts, keys, inverse: false, **options)
        keys.map { |key|
          nils, vals = Array.wrap(opts.delete(key)).uniq.partition(&:nil?)

          Array.wrap(options[:locale] || Mobility.locale).map { |locale|
            column_name = Column.column_name_for(key, locale)
            node = arel_table[column_name]

            next node.eq(nil) if vals.empty?

            query = node_in(node, vals)
            query = query.or(node.eq(nil)) unless nils.empty?
            query
          }.inject(&(inverse ? :and : :or))
        }.inject(&(inverse ? :or : :and))
      end

      private

      def node_in(node, vals)
        vals.size == 1 ? node.eq(vals.first) : node.in(vals)
      end
    end
  end
end
