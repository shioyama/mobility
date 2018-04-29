# frozen_string_literal: true

module Mobility
  module Backends
    module ActiveRecord
=begin

Internal module builder defining query methods for Postgres backends. Including
class must define the following methods:

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
          @column_affix = options[:column_affix]

          q = self

          define_method :where! do |opts, *rest|
            if i18n_keys = q.extract_attributes(opts)
              opts = opts.with_indifferent_access
              query = q.create_query!(opts, i18n_keys)

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
                query = q.create_query!(opts, i18n_keys, inverse: true)

                super(opts, *rest).where(query)
              else
                super(opts, *rest)
              end
            end
          end
          relation.mobility_where_chain.include(mod)
        end

        # Create +where+ query for specified key and value
        #
        # @note This is a destructive operation, it will modify +opts+.
        # @param [Hash] opts Hash of attribute/value pairs
        # @param [Array] keys Translated attribute names
        # @option [Boolean] inverse (false) If true, create a +not+ query
        #   instead of a +where+ query
        # @return [Arel::Node] Arel node to pass to +where+
        def create_query!(opts, keys, inverse: false)
          keys.map { |key|
            values = Array.wrap(opts.delete(key)).uniq
            send(inverse ? :not_query : :where_query, key, values, Mobility.locale)
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

        # Create +where+ query for specified key and values
        #
        # @param [String] key Translated attribute name
        # @param [Array] values Values to match
        # @param [Symbol] locale Locale to query for
        # @return [Arel::Node] Arel node to pass to +where+
        def where_query(key, values, locale)
          nils, vals = values.partition(&:nil?)

          return absent(key, locale) if vals.empty?

          node = matches(key, locale)
          vals = vals.map(&method(:quote))

          query = vals.size == 1 ? node.eq(vals.first) : node.in(vals)
          query = query.or(absent(key, locale)) unless nils.empty?
          query
        end

        # Create +not+ query for specified key and values
        #
        # @param [String] key Translated attribute name
        # @param [Array] values Values to match
        # @param [Symbol] locale Locale to query for
        # @return [Arel::Node] Arel node to pass to +where+
        def not_query(key, values, locale)
          vals = values.map(&method(:quote))
          node = matches(key, locale)

          query = vals.size == 1 ? node.eq(vals.first) : node.in(vals)
          query.not.and(exists(key, locale))
        end
      end
      private_constant :PgQueryMethods
    end
  end
end
