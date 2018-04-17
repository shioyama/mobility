# frozen_string_literal: true

module Mobility
  module Backends
    module Sequel
=begin

Defines query methods for Postgres backends. Including class must define two
methods:

- a method +matches+ which takes a key (column name) and a locale to match and
  returns an SQL expression checking that the column has the specified value
  in the specified locale
- a method +exists+ which takes a key (column name) and locale, and returns
  an SQL expression which checks that the column has a value in the locale
- a method +quote+ which quotes the value to be matched

(The +matches+ and +exists+ methods are implemented slightly differently for
hstore/json/jsonb/container backends.)

@see Mobility::Backends::Sequel::Json::QueryMethods
@see Mobility::Backends::Sequel::Jsonb::QueryMethods
@see Mobility::Backends::Sequel::Hstore::QueryMethods
@see Mobility::Backends::Sequel::Container::JsonQueryMethods
@see Mobility::Backends::Sequel::Container::JsonbQueryMethods

=end
      module PgQueryMethods
        attr_reader :column_affix

        def initialize(attributes, options)
          super
          @column_affix = "#{options[:column_prefix]}%s#{options[:column_suffix]}"
          define_query_methods
        end

        # Create query for conditions and translated keys
        # @note This is a destructive action, it will alter +cond+.
        #
        # @param [Hash] cond Hash of attribute/value pairs
        # @param [Array] keys Translated attribute names
        # @param [Boolean] invert Invert query, true for +exclude+, false otherwise
        # @return [Sequel::SQL::Expression] Query expression
        def create_query!(cond, keys, invert = false)
          keys.map { |key|
            values = cond.delete(key)
            values = values.is_a?(Array) ? values.uniq: [values]
            create_query_op(key, values, invert)
          }.inject(invert ? :| : :&)
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

        private

        def define_query_methods
          %w[exclude or where].each do |method_name|
            define_query_method(method_name)
          end
        end

        def define_query_method(method_name)
          q = self

          define_method method_name do |*cond, &block|
            if i18n_keys = q.extract_attributes(cond.first)
              cond = cond.first

              query = q.create_query!(cond, i18n_keys, method_name == "exclude")
              if method_name == "or"
                query = ::Sequel.&(cond, query) unless cond.empty?
                super(query, &block)
              else
                super(cond, &block).where(query)
              end
            else
              super(*cond, &block)
            end
          end
        end

        def create_query_op(key, values, invert)
          locale = Mobility.locale.to_s
          values = values.map(&method(:quote))
          values = values.first if values.size == 1

          match = matches(key, locale) =~ values

          if invert
            exists(key, locale) & ~match
          else
            values.nil? ? ~exists(key, locale) : match
          end
        end


        def column_name(attribute)
          (column_affix % attribute).to_sym
        end
      end
    end
  end
end
