module Mobility
  module Backend
    class ActiveRecord::Column::QueryMethods < Backend::ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        super
        attributes_extractor = @attributes_extractor

        define_method :where! do |opts, *rest|
          if i18n_keys = attributes_extractor.call(opts)
            opts = opts.with_indifferent_access
            i18n_keys.each { |attr| opts[Column.column_name_for(attr)] = opts.delete(attr) }
          end
          super(opts, *rest)
        end

        attributes.each do |attribute|
          define_method :"find_by_#{attribute}" do |value|
            find_by(Column.column_name_for(attribute) => value)
          end
        end
      end

      def extended(relation)
        super
        attributes_extractor = @attributes_extractor

        mod = Module.new do
          define_method :not do |opts, *rest|
            if i18n_keys = attributes_extractor.call(opts)
              opts = opts.with_indifferent_access
              i18n_keys.each { |attr| opts[Column.column_name_for(attr)] = opts.delete(attr) }
            end
            super(opts, *rest)
          end
        end
        relation.model.const_get(:MobilityWhereChain).prepend(mod)
      end
    end
  end
end
