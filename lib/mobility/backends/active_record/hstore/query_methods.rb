module Mobility
  module Backends
    class ActiveRecord::Hstore::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, _)
        super
        q = self

        define_method :where! do |opts, *rest|
          if i18n_keys = q.extract_attributes(opts)
            m = arel_table
            opts = opts.with_indifferent_access

            i18n_query = i18n_keys.map { |key|
              column = m[key.to_sym]
              value = opts.delete(key)

              value.nil? ?
                q.has_locale(column).not :
                q.equals_value(column, value)
            }.inject(&:and)

            opts.empty? ? super(i18n_query) : super(opts, *rest).where(i18n_query)
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

              i18n_query = i18n_keys.map { |key|
                column = m[key.to_sym]
                q.has_locale(column).
                  and(q.equals_value(column, opts.delete(key)).not)
              }.inject(&:and)

              super(opts, *rest).where(i18n_query)
            else
              super(opts, *rest)
            end
          end
        end
        relation.mobility_where_chain.include(mod)
      end

      def equals_value(column, value)
        build_infix(:'->', column, quoted_locale).eq(Arel::Nodes.build_quoted(value.to_s))
      end

      def has_locale(column)
        build_infix(:'?', column, quoted_locale)
      end

      private

      def build_infix(*args)
        Arel::Nodes::InfixOperation.new(*args)
      end

      def quoted_locale
        Arel::Nodes.build_quoted(Mobility.locale.to_s)
      end
    end
  end
end
