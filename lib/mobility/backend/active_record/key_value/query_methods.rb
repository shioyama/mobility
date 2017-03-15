module Mobility
  module Backend
    class ActiveRecord::KeyValue::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        super
        association_name, translation_class = options[:association_name], options[:class_name]
        @association_name    = association_name

        define_join_method(association_name, translation_class)
        define_query_methods(association_name)

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

        mod = Module.new do
          define_method :not do |opts, *rest|
            if i18n_keys = attributes_extractor.call(opts)
              opts = opts.with_indifferent_access
              i18n_keys.each { |attr| opts["#{attr}_#{association_name}"] = { value: opts.delete(attr) }}
              super(opts, *rest).send(:"join_#{association_name}", *i18n_keys)
            else
              super(opts, *rest)
            end
          end
        end
        relation.model.mobility_where_chain.prepend(mod)
      end

      private

      def define_join_method(association_name, translation_class)
        define_method :"join_#{association_name}" do |*attributes, **options|
          attributes.inject(self) do |relation, attribute|
            t = translation_class.arel_table.alias(:"#{attribute}_#{association_name}")
            m = arel_table
            join_type = options[:outer_join] ? Arel::Nodes::OuterJoin : Arel::Nodes::InnerJoin
            relation.joins(m.join(t, join_type).
                           on(t[:key].eq(attribute).
                              and(t[:locale].eq(Mobility.locale).
                                  and(t[:translatable_type].eq(name).
                                      and(t[:translatable_id].eq(m[:id]))))).join_sources)
          end
        end
      end

      def define_query_methods(association_name)
        attributes_extractor = @attributes_extractor

        define_method :where! do |opts, *rest|
          if i18n_keys = attributes_extractor.call(opts)
            opts = opts.with_indifferent_access
            i18n_nulls = i18n_keys.select { |key| opts[key].nil? }
            i18n_keys.each { |attr| opts["#{attr}_#{association_name}"] = { value: opts.delete(attr) }}
            super(opts, *rest).
              send("join_#{association_name}", *(i18n_keys - i18n_nulls)).
              send("join_#{association_name}", *i18n_nulls, outer_join: true)
          else
            super(opts, *rest)
          end
        end
      end
    end
  end
end
