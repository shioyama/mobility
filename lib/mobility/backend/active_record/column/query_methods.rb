module Mobility
  module Backend
    class ActiveRecord::Column::QueryMethods < Backend::ActiveRecord::QueryMethods
      def initialize(attributes, _)
        super
        attributes_extractor = @attributes_extractor
        @opts_converter = opts_converter = lambda do |opts|
          if i18n_keys = attributes_extractor.call(opts)
            opts = opts.with_indifferent_access
            i18n_keys.each { |attr| opts[Column.column_name_for(attr)] = opts.delete(attr) }
          end
          return opts
        end

        define_method :where! do |opts, *rest|
          super(opts_converter.call(opts), *rest)
        end

        attributes.each do |attribute|
          define_method :"find_by_#{attribute}" do |value|
            find_by(Column.column_name_for(attribute) => value)
          end
        end
      end

      def extended(relation)
        super
        opts_converter = @opts_converter

        mod = Module.new do
          define_method :not do |opts, *rest|
            super(opts_converter.call(opts), *rest)
          end
        end
        relation.mobility_where_chain.include(mod)
      end
    end
  end
end
