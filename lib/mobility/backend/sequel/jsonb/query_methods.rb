Sequel.extension :pg_json, :pg_json_ops

module Mobility
  module Backend
    class Sequel::Jsonb::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **)
        super

        define_query_methods

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(::Sequel.pg_jsonb_op(attribute).contains({ Mobility.locale => value })).
              select_all(model.table_name).first
          end
        end
      end

      private

      def define_query_methods
        attributes_extractor = @attributes_extractor

        %w[exclude or where].each do |method_name|
          invert = method_name == "exclude"

          define_method method_name do |*conds, &block|
            if i18n_keys = attributes_extractor.call(conds.first)
              locale = Mobility.locale.to_s
              table_name = model.table_name
              cond = conds.first

              i18n_query = i18n_keys.inject(::Sequel.expr(!invert)) do |expr, attr|
                value = cond.delete(attr)
                attr_jsonb = ::Sequel.pg_jsonb_op(attr)
                contains_value = attr_jsonb.contains({ locale => value })
                has_key = attr_jsonb.has_key?(locale)
                if invert
                  expr.|(has_key & ~contains_value)
                else
                  expr.&(value.nil? ? ~has_key : contains_value)
                end
              end
              super(cond, &block).where(i18n_query)
            else
              super(*conds, &block)
            end
          end
        end
      end
    end
  end
end
