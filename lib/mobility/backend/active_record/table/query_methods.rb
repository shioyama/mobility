module Mobility
  module Backend
    class ActiveRecord::Table::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        super
        association_name     = options[:association_name]
        foreign_key          = options[:foreign_key]
        @association_name    = association_name
        attributes_extractor = @attributes_extractor
        translation_class    = options[:model_class].const_get(:Translation)
        @translation_class   = translation_class

        define_method :"join_#{association_name}" do |**options|
          (@__mobility_table_joined ||= []) << association_name
          t = translation_class.arel_table
          m = arel_table
          join_type = options[:outer_join] ? Arel::Nodes::OuterJoin : Arel::Nodes::InnerJoin
          joins(m.join(t, join_type).
                on(t[foreign_key].eq(m[:id]).
                   and(t[:locale].eq(Mobility.locale))).join_sources)
        end

        define_method :where! do |opts, *rest|
          if i18n_keys = attributes_extractor.call(opts)
            opts = opts.with_indifferent_access
            options = { outer_join: i18n_keys.all? { |attr| opts[attr].nil? } }
            i18n_keys.each { |attr| opts["#{translation_class.table_name}.#{attr}"] = opts.delete(attr) }
            if (@__mobility_table_joined || []).include?(association_name)
              super(opts, *rest)
            else
              super(opts, *rest).send("join_#{association_name}", options)
            end
          else
            super(opts, *rest)
          end
        end

        attributes.each do |attribute|
          define_method :"find_by_#{attribute}" do |value|
            find_by(attribute.to_sym => value)
          end
        end
      end

      def extended(relation)
        super
        association_name     = @association_name
        attributes_extractor = @attributes_extractor
        translation_class    = @translation_class

        mod = Module.new do
          define_method :not do |opts, *rest|
            if i18n_keys = attributes_extractor.call(opts)
              opts = opts.with_indifferent_access
              i18n_keys.each { |attr| opts["#{translation_class.table_name}.#{attr}"] = opts.delete(attr) }
              super(opts, *rest).send("join_#{association_name}")
            else
              super(opts, *rest)
            end
          end
        end
        relation.model.mobility_where_chain.prepend(mod)
      end
    end
  end
end
