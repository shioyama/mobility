require "mobility/backends/sequel/query_methods"

module Mobility
  module Backends
    class Sequel::Table::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, association_name: nil, model_class: nil, subclass_name: nil, **options)
        super
        translation_class = model_class.const_get(subclass_name)

        define_join_method(association_name, translation_class, **options)
        define_query_methods(association_name, translation_class, **options)

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(attribute => value).select_all(model.table_name).first
          end
        end
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
        attributes_extractor = @attributes_extractor

        # See note in AR Table QueryMethods class about limitations of
        # query methods on translated attributes when searching on nil values.
        #
        %w[exclude or where].each do |method_name|
          define_method method_name do |*conds, &block|
            if i18n_keys = attributes_extractor.call(conds.first)
              cond = conds.first.dup
              outer_join = method_name == "or" || i18n_keys.all? { |key| cond[key].nil? }
              i18n_keys.each { |attr| cond[::Sequel[translation_class.table_name][attr]] = cond.delete(attr) }
              super(cond, &block).send("join_#{association_name}", outer_join: outer_join)
            else
              super(*conds, &block)
            end
          end
        end
      end
    end
  end
end
