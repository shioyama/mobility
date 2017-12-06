module Mobility
  module Backends
    module ActiveRecord
=begin

Defines query methods for Postgres backends. Including class must define a
single method, +contains_value+, which accepts a column and value to match, and
returns an Arel node.

This module avoids 99% duplication between hstore and jsonb backend querying
code.

@see Mobility::Backends::ActiveRecord::Jsonb::QueryMethods
@see Mobility::Backends::ActiveRecord::Hstore::QueryMethods

=end
      module PgQueryMethods
        def initialize(attributes, _)
          super
          q = self

          define_method :where! do |opts, *rest|
            if i18n_keys = q.extract_attributes(opts)
              opts = opts.with_indifferent_access
              query = q.create_where_query(opts, i18n_keys, arel_table)

              opts.empty? ? super(query) : super(opts, *rest).where(query)
            else
              super(opts, *rest)
            end
          end
        end

        def extended(relation)
          super
          q = self
          m = relation.model.arel_table

          mod = Module.new do
            define_method :not do |opts, *rest|
              if i18n_keys = q.extract_attributes(opts)
                opts = opts.with_indifferent_access
                query = q.create_not_query(opts, i18n_keys, m)

                super(opts, *rest).where(query)
              else
                super(opts, *rest)
              end
            end
          end
          relation.mobility_where_chain.include(mod)
        end

        def create_where_query(opts, keys, arel_table)
          keys.map { |key|
            column = arel_table[key.to_sym]
            value = opts.delete(key)

            value.nil? ?
              has_locale(column).not :
              contains_value(column, value)
          }.inject(&:and)
        end

        def create_not_query(opts, keys, arel_table)
          keys.map { |key|
            column = arel_table[key.to_sym]
            has_locale(column).
              and(contains_value(column, opts.delete(key)).not)
          }.inject(&:and)
        end

        private

        def has_locale(column)
          build_infix(:'?', column, quoted_locale)
        end

        def build_infix(*args)
          Arel::Nodes::InfixOperation.new(*args)
        end

        def quoted_locale
          Arel::Nodes.build_quoted(Mobility.locale.to_s)
        end
      end
    end
  end
end
