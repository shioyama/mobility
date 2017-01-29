Sequel.extension :pg_hstore, :pg_hstore_ops

module Mobility
  module Backend
    class Sequel::Hstore::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **options)
        super
        attributes_extractor = @attributes_extractor

        define_method :_filter_or_exclude do |invert, clause, *conds, &block|
          if (clause == :where) && i18n_keys = attributes_extractor.call(conds.first)
            locale = Mobility.locale.to_s
            table_name = model.table_name
            cond = conds.first

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
            super(invert, clause, *conds, &block).where(i18n_query)
          else
            super(invert, clause, *conds, &block)
          end
        end

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(::Sequel.hstore(attribute.to_sym).contains(::Sequel.hstore({ Mobility.locale.to_s => value }))).
              select_all(model.table_name).first
          end
        end
      end
    end
  end
end
