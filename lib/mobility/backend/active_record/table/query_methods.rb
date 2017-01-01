module Mobility
  module Backend
    class ActiveRecord::Table::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        association_name, translations_class = options[:association_name], options[:class_name]
        @association_name = association_name
        @attributes = attributes

        define_method :"join_#{association_name}" do |*attributes, **options|
          attributes.inject(self) do |relation, attribute|
            t = translations_class.arel_table.alias(:"#{attribute}_#{association_name}")
            m = arel_table
            join_type = options[:outer_join] ? Arel::Nodes::OuterJoin : Arel::Nodes::InnerJoin
            relation.joins(m.join(t, join_type).
                           on(t[:key].eq(attribute).
                              and(t[:locale].eq(Mobility.locale).
                                  and(t[:translatable_type].eq(name).
                                      and(t[:translatable_id].eq(m[:id]))))).join_sources)
          end
        end

        define_method :where! do |opts, *rest|
          if opts.is_a?(Hash) && (keys = opts.keys.map(&:to_s) & attributes).present?
            opts = opts.stringify_keys
            null_keys = keys.select { |key| opts[key].nil? }
            keys.each { |attr| opts["#{attr}_#{association_name}"] = { value: opts.delete(attr) }}
            super(opts, *rest).
              send("join_#{association_name}", *(keys - null_keys)).
              send("join_#{association_name}", *null_keys, outer_join: true)
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
        model_class = relation.model
        attributes, association_name = @attributes, @association_name
        mod = Module.new do
          define_method :not do |opts, *rest|
            if opts.is_a?(Hash) && (keys = opts.keys.map(&:to_s) & attributes).present?
              opts = opts.stringify_keys
              keys.each { |attr| opts["#{attr}_#{association_name}"] = { value: opts.delete(attr) }}
              super(opts, *rest).send(:"join_#{association_name}", *keys)
            else
              super(opts, *rest)
            end
          end
        end
        model_class.const_get(:MobilityWhereChain).prepend(mod)
      end
    end
  end
end
