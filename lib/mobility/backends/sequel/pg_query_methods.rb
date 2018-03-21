module Mobility
  module Backends
    module Sequel
=begin

Defines query methods for Postgres backends. Including class must define two
methods:

- a method +matches+ which takes a key (column name), value and locale and
  returns an SQL expression, and checks that the column has the specified value
  in the specified locale
- a method +has_locale+ which takes a key (column name) and locale, and returns
  an SQL expression which checks that the column has a value in the locale

(The +matches+ and +has_locale+ methods are implemented slightly differently
for hstore/json/jsonb/container backends.)

=end
      module PgQueryMethods
        def initialize(attributes, _)
          super
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
            values = [values] unless values.is_a?(Array)
            values.map { |value| create_query_op(key, value, invert) }.inject(&:|)
          }.inject(invert ? :| : :&)
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

        def create_query_op(key, value, invert)
          locale = Mobility.locale.to_s

          if invert
            has_locale(key, locale) & ~matches(key, value, locale)
          else
            value.nil? ? ~has_locale(key, locale) : matches(key, value, locale)
          end
        end

        def matches(_key, _value, _locale)
          raise NotImplementedError
        end

        def has_locale(_key, _locale)
          raise NotImplementedError
        end
      end
    end
  end
end
