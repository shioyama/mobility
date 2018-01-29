require "mobility/backends/sequel/query_methods"

module Mobility
  module Backends
    class Sequel::Column::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, _)
        super
        q = self

        %w[exclude or where].each do |method_name|
          define_method method_name do |*conds, &block|
            if keys = q.extract_attributes(conds.first)
              cond = conds.first.dup
              keys.each { |attr| cond[Column.column_name_for(attr)] = cond.delete(attr) }
              super(cond, &block)
            else
              super(*conds, &block)
            end
          end
        end
      end
    end
  end
end
