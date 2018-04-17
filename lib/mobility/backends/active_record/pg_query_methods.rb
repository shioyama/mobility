# frozen_string_literal: true

module Mobility
  module Backends
    module ActiveRecord
=begin

Defines query methods for Postgres backends. Including class must define two
methods:

- a method +matches+ which takes an attribute, and a locale to match, and
  returns an Arel node which is used to check that the attribute has the
  specified value in the specified locale
- a method +exists+ which takes an attribute and a locale and
  returns an Arel node checking that a value exists for the attribute in the
  specified locale
- a method +quote+ which quotes the value to be matched
- an optional method +absent+ which takes an attribute and a locale and returns
  an Arel node checking that the value for the attribute does not exist in the
  specified locale. Defaults to +exists(key, locale).not+.

This module avoids a lot of duplication between hstore/json/jsonb/container
backend querying code.

@see Mobility::Backends::ActiveRecord::Json::QueryMethods
@see Mobility::Backends::ActiveRecord::Jsonb::QueryMethods
@see Mobility::Backends::ActiveRecord::Hstore::QueryMethods
@see Mobility::Backends::ActiveRecord::Container::JsonQueryMethods
@see Mobility::Backends::ActiveRecord::Container::JsonbQueryMethods

=end
      module PgQueryMethods
        attr_reader :arel_table, :column_affix

        def initialize(attributes, options)
          super
          @arel_table   = options[:model_class].arel_table
          @column_affix = "#{options[:column_prefix]}%s#{options[:column_suffix]}"

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
            nils, vals = Array.wrap(values).uniq.partition(&:nil?)

            next absent(key, locale) if vals.empty?

            node = matches(key, locale)
            vals = vals.map(&method(:quote))

            query = vals.size == 1 ? node.eq(vals.first) : node.in(vals)
            query = query.or(absent(key, locale)) unless nils.empty?
            query
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
            vals = Array.wrap(values).uniq.map(&method(:quote))
            node = matches(key, locale)

            query = vals.size == 1 ? node.eq(vals.first) : node.in(vals)
            query.not.and(exists(key, locale))
          }.inject(&:and)
        end

        def matches(_key, _locale)
          raise NotImplementedError
        end

        def exists(_key, _locale)
          raise NotImplementedError
        end

        def quote(_value)
          raise NotImplementedError
        end

        def absent(key, locale)
          exists(key, locale).not
        end

        private

        def build_infix(*args)
          arel_table.grouping(Arel::Nodes::InfixOperation.new(*args))
        end

        def build_quoted(value)
          Arel::Nodes.build_quoted(value.to_s)
        end

        def column_name(attribute)
          column_affix % attribute
        end
      end
    end
  end
end
