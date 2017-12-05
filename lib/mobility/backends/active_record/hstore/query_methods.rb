module Mobility
  module Backends
    class ActiveRecord::Hstore::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, _)
        super
        attributes_extractor = @attributes_extractor

        define_method :where! do |opts, *rest|
          if i18n_keys = attributes_extractor.call(opts)
            m = arel_table
            locale = Arel::Nodes.build_quoted(Mobility.locale.to_s)
            opts = opts.with_indifferent_access
            infix = Arel::Nodes::InfixOperation

            i18n_query = i18n_keys.map { |key|
              column = m[key.to_sym]
              value = opts.delete(key)

              if value.nil?
                infix.new(:'?', column, locale).not
              else
                infix.new(:'->', m[key.to_sym], locale).eq(value)
              end
            }.inject(&:and)

            opts.empty? ? super(i18n_query) : super(opts, *rest).where(i18n_query)
          else
            super(opts, *rest)
          end
        end
      end

      def extended(relation)
        super
        attributes_extractor = @attributes_extractor
        m = relation.model.arel_table

        mod = Module.new do
          define_method :not do |opts, *rest|
            if i18n_keys = attributes_extractor.call(opts)
              locale = Arel::Nodes.build_quoted(Mobility.locale.to_s)
              opts = opts.with_indifferent_access
              infix = Arel::Nodes::InfixOperation

              i18n_query = i18n_keys.map { |key|
                column = m[key.to_sym]
                value = Arel::Nodes.build_quoted(opts.delete(key).to_s)
                has_key = infix.new(:'?', column, locale)
                not_eq_value = infix.new(:'->', column, locale).not_eq(value)
                has_key.and(not_eq_value)
              }.inject(&:and)

              super(opts, *rest).where(i18n_query)
            else
              super(opts, *rest)
            end
          end
        end
        relation.mobility_where_chain.include(mod)
      end
    end
  end
end
