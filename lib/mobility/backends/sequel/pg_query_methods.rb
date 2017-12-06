module Mobility
  module Backends
    module Sequel
=begin

Defines query methods for Postgres backends. Including class must define a
single private method, +build_pg_op+, which takes a single argument and
generates an appropriate operator (using either +::Sequel.hstore_op+ or
+::Sequel.pg_jsonb_op+).

=end
      module PgQueryMethods

        # Create query for conditions and translated keys
        # @note This is a destructive action, it will alter +cond+.
        #
        # @param [Hash] cond Hash of attribute/value pairs
        # @param [Array] keys Translated attribute names
        # @param [Boolean] invert Invert query, true for +exclude+, false otherwise
        # @return [Sequel::SQL::Expression] Query expression
        def create_query!(cond, keys, invert = false)
          keys.map { |key|
            create_query_op(key, cond.delete(key), invert)
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
          op = build_pg_op(key)
          contains_value = op.contains(locale => value.to_s)
          has_key = op.has_key?(locale)

          if invert
            has_key & ~contains_value
          else
            value.nil? ? ~has_key : contains_value
          end
        end

        def build_pg_op
          raise NotImplementedError
        end
      end
    end
  end
end
