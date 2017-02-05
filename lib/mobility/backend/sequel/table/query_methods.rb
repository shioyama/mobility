module Mobility
  module Backend
    class Sequel::Table::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **options)
        super
        association_name     = options[:association_name]
        @association_name    = association_name
        foreign_key          = options[:foreign_key]
        attributes_extractor = @attributes_extractor
        translation_class    = options[:model_class].const_get(:Translation)
        @translation_class   = translation_class

        define_method :"join_#{association_name}" do |**options|
          (@__mobility_table_joined ||= []) << association_name
          join_type = options[:outer_join] ? :left_outer : :inner
          join_table(join_type,
                     translation_class.table_name,
                     {
                       locale: Mobility.locale.to_s,
                       foreign_key => ::Sequel[model.table_name][:id]
                     })
        end

        # See note in AR Table QueryMethods class about limitations of
        # query methods on translated attributes when searching on nil values.
        #
        define_method :_filter_or_exclude do |invert, clause, *cond, &block|
          if i18n_keys = attributes_extractor.call(cond.first)
            cond = cond.first.dup
            outer_join = i18n_keys.all? { |key| cond[key].nil? }
            i18n_keys.each { |attr| cond[::Sequel[translation_class.table_name][attr]] = cond.delete(attr) }
            if (@__mobility_table_joined || []).include?(association_name)
              super(invert, clause, cond, &block)
            else
              super(invert, clause, cond, &block).send("join_#{association_name}", outer_join: outer_join)
            end
          else
            super(invert, clause, *cond, &block)
          end
        end

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(attribute => value).select_all(model.table_name).first
          end
        end
      end
    end
  end
end
