module Mobility
  module Backend
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

      def define_join_method(association_name, translation_class, table_name: nil, foreign_key: nil, **_)
        define_method :"join_#{association_name}" do |**options|
          return self if (@__mobility_table_joined || []).include?(table_name)
          (@__mobility_table_joined ||= []) << table_name
          join_type = options[:outer_join] ? :left_outer : :inner
          join_table(join_type,
                     translation_class.table_name,
                     {
                       locale: Mobility.locale.to_s,
                       foreign_key => ::Sequel[model.table_name][:id]
                     })
        end
      end

      def define_query_methods(association_name, translation_class, **_)
        attributes_extractor = @attributes_extractor

        # See note in AR Table QueryMethods class about limitations of
        # query methods on translated attributes when searching on nil values.
        #
        define_method :_filter_or_exclude do |invert, clause, *cond, &block|
          if i18n_keys = attributes_extractor.call(cond.first)
            cond = cond.first.dup
            outer_join = i18n_keys.all? { |key| cond[key].nil? }
            i18n_keys.each { |attr| cond[::Sequel[translation_class.table_name][attr]] = cond.delete(attr) }
            super(invert, clause, cond, &block).send("join_#{association_name}", outer_join: outer_join)
          else
            super(invert, clause, *cond, &block)
          end
        end
      end
    end
  end
end
