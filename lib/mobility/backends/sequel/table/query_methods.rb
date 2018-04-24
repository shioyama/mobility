# frozen_string_literal: true
require "mobility/backends/sequel/query_methods"

module Mobility
  module Backends
    module Sequel
      class Table::QueryMethods < QueryMethods
        def initialize(attributes, association_name: nil, model_class: nil, subclass_name: nil, **options)
          super
          translation_class = model_class.const_get(subclass_name)

          define_join_method(association_name, translation_class, **options)
          define_query_methods(association_name, translation_class, **options)
        end

        def define_join_method(association_name, translation_class, table_name: nil, foreign_key: nil, **)
          define_method :"join_#{association_name}" do |**options|
            if joins = @opts[:join]
              # Return self if we've already joined this table
              return self if joins.any? { |clause| clause.table_expr == table_name }
            end

            join_type = options[:outer_join] ? :left_outer : :inner
            join_table(join_type,
                       translation_class.table_name,
                       {
                         locale: Mobility.locale.to_s,
                         foreign_key => ::Sequel[model.table_name][:id]
                       })
          end
        end

        def define_query_methods(association_name, translation_class, **)
          q = self

          # See note in AR Table QueryMethods class about limitations of
          # query methods on translated attributes when searching on nil values.
          #
          %w[exclude or where].each do |method_name|
            define_method method_name do |*conds, &block|
              if i18n_keys = q.extract_attributes(conds.first)
                cond = conds.first.dup
                outer_join = method_name == "or" || i18n_keys.all? { |key| cond[key].nil? }
                i18n_keys.each do |attr|
                  cond[::Sequel[translation_class.table_name][attr]] = q.collapse cond.delete(attr)
                end
                super(cond, &block).send("join_#{association_name}", outer_join: outer_join)
              else
                super(*conds, &block)
              end
            end
          end
        end
      end
      Table.private_constant :QueryMethods
    end
  end
end
