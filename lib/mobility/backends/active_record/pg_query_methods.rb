module Mobility
  module Backends
    module ActiveRecord
=begin

Defines query methods for Postgres backends. Including class must define a
single method, +matches+, which accepts a column, value and locale to
match, and returns an Arel node.

This module avoids 99% duplication between hstore and jsonb backend querying
code.

@see Mobility::Backends::ActiveRecord::Jsonb::QueryMethods
@see Mobility::Backends::ActiveRecord::Hstore::QueryMethods

=end
      module PgQueryMethods
        attr_reader :arel_table

        def initialize(attributes, options)
          super
          @arel_table = options[:model_class].arel_table

          q = self

          define_method :where! do |opts, *rest|
            if i18n_keys = q.extract_attributes(opts)
              opts = opts.with_indifferent_access
              query = q.create_where_query!(opts, i18n_keys)

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
                query = q.create_not_query!(opts, i18n_keys)

                super(opts, *rest).where(query)
              else
                super(opts, *rest)
              end
            end
          end
          relation.mobility_where_chain.include(mod)
        end

        # Create +where+ query for options hash, translated keys and arel_table
        # @note This is a destructive operation, it will modify +opts+.
        #
        # @param [Hash] opts Hash of attribute/value pairs
        # @param [Array] keys Translated attribute names
        # @return [Arel::Node] Arel node to pass to +where+
        def create_where_query!(opts, keys)
          locale = Mobility.locale
          keys.map { |key|
            values = opts.delete(key)

            next has_locale(key, locale).not if values.nil?

            Array.wrap(values).map { |value|
              value.nil? ?
                has_locale(key, locale).not :
                matches(key, value, locale)
            }.inject(&:or)
          }.inject(&:and)
        end

        # Create +not+ query for options hash and translated keys
        # @note This is a destructive operation, it will modify +opts+.
        #
        # @param [Hash] opts Hash of attribute/value pairs
        # @param [Array] keys Translated attribute names
        # @return [Arel::Node] Arel node to pass to +where+
        def create_not_query!(opts, keys)
          locale = Mobility.locale
          keys.map { |key|
            values = opts.delete(key)

            Array.wrap(values).map { |value|
              matches(key, value, locale).not
            }.inject(has_locale(key, locale), &:and)
          }.inject(&:and)
        end

        private

        def matches(_key, _value, _locale)
          raise NotImplementedError
        end

        def has_locale(key, locale)
          build_infix(:'?', arel_table[key], quote(locale))
        end

        def build_infix(*args)
          arel_table.grouping(Arel::Nodes::InfixOperation.new(*args))
        end

        def quote(value)
          Arel::Nodes.build_quoted(value.to_s)
        end
      end
    end
  end
end
