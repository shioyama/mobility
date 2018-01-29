require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Column::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, _)
        super
        q = self

        define_method :where! do |opts, *rest|
          super(q.convert_opts(opts), *rest)
        end
      end

      def extended(relation)
        super
        q = self

        mod = Module.new do
          define_method :not do |opts, *rest|
            super(q.convert_opts(opts), *rest)
          end
        end
        relation.mobility_where_chain.include(mod)
      end

      def convert_opts(opts)
        if i18n_keys = extract_attributes(opts)
          opts = opts.with_indifferent_access
          i18n_keys.each { |attr| opts[Column.column_name_for(attr)] = opts.delete(attr) }
        end
        opts
      end
    end
  end
end
