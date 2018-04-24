# frozen_string_literal: true
require "mobility/backends/sequel/query_methods"

module Mobility
  module Backends
    module Sequel
      class Column::QueryMethods < QueryMethods
        def initialize(attributes, _)
          super
          q = self

          %w[exclude or where].each do |method_name|
            define_method method_name do |*conds, &block|
              if i18n_keys = q.extract_attributes(conds.first)
                cond = conds.first.dup
                i18n_keys.each do |attr|
                  cond[Backends::Column.column_name_for(attr)] = q.collapse cond.delete(attr)
                end
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
end
