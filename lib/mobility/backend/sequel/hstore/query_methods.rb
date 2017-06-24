Sequel.extension :pg_hstore, :pg_hstore_ops

module Mobility
  module Backend
    class Sequel::Hstore::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **)
        super

        define_query_methods

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(::Sequel.hstore(attribute.to_sym).contains(::Sequel.hstore({ Mobility.locale.to_s => value }))).
              select_all(model.table_name).first
          end
        end
      end

      private

      def define_query_methods
        attributes_extractor = @attributes_extractor

        %w[exclude or where].each do |method_name|
          invert = method_name == "exclude"

          define_method method_name do |*cond, &block|
            if i18n_keys = attributes_extractor.call(cond.first)
              locale = Mobility.locale.to_s
              table_name = model.table_name
              cond = cond.first

              i18n_query = i18n_keys.inject(::Sequel.expr(!invert)) do |expr, attr|
                value = cond.delete(attr)
                attr_hstore = ::Sequel.hstore_op(attr)
                contains_value = attr_hstore.contains({ locale => value.to_s })
                has_key = attr_hstore.has_key?(locale)
                if invert
                  expr.|(has_key & ~contains_value)
                else
                  expr.&(value.nil? ? ~has_key : contains_value)
                end
              end
              if method_name == "or"
                cond.empty? ? super(i18n_query, &block) : super(::Sequel.&(cond, i18n_query), &block)
              else
                super(cond, &block).where(i18n_query)
              end
            else
              super(*cond, &block)
            end
          end
        end
      end
    end
  end
end
