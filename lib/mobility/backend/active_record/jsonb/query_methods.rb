module Mobility
  module Backend
    class ActiveRecord::Jsonb::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        super
        attributes_extractor = @attributes_extractor

        define_method :where! do |opts, *rest|
          if i18n_keys = attributes_extractor.call(opts)
            m = arel_table
            locale = Arel::Nodes.build_quoted(Mobility.locale.to_s)
            opts = opts.with_indifferent_access
            infix = Arel::Nodes::InfixOperation

            i18n_query = i18n_keys.inject(nil) { |ops, attr|
              column = m[attr.to_sym]
              value = opts.delete(attr)

              op =
                if value.nil?
                  infix.new(:'?', column, locale).not
                else
                  predicate = Arel::Nodes.build_quoted({ Mobility.locale => value }.to_json)
                  infix.new(:'@>', m[attr.to_sym], predicate)
                end
              ops ? ops.and(op) : op
            }

            opts.empty? ? where(i18n_query) : super(opts, *rest).where(i18n_query)
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

              i18n_query = i18n_keys.inject(nil) { |ops, attr|
                column = m[attr.to_sym]
                has_key = infix.new(:'?', column, locale)
                predicate = Arel::Nodes.build_quoted({ Mobility.locale => opts.delete(attr) }.to_json)
                not_eq_value = infix.new(:'@>', m[attr.to_sym], predicate).not
                op = has_key.and(not_eq_value)
                ops ? ops.and(op) : op
              }

              super(opts, *rest).where(i18n_query)
            else
              super(opts, *rest)
            end
          end
        end
        relation.model.mobility_where_chain.prepend(mod)
      end
    end
  end
end
