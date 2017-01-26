module Mobility
  module Backend
    class Sequel::KeyValue::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **options)
        super
        attributes_extractor = @attributes_extractor
        association_name, translations_class = options[:association_name], options[:class_name]

        define_method :"join_#{association_name}" do |*attributes, **options|
          attributes.inject(self) do |relation, attribute|
            join_type = options[:outer_join] ? :left_outer : :inner
            relation.join_table(join_type,
                                translations_class.table_name,
                                {
                                  key: attribute.to_s,
                                  locale: Mobility.locale.to_s,
                                  translatable_type: model.name,
                                  translatable_id: ::Sequel[:"#{model.table_name}"][:id]
                                },
                                table_alias: "#{attribute}_#{association_name}")
          end
        end

        # TODO: find a better way to do this that doesn't involve overriding
        # a private method...
        define_method :_filter_or_exclude do |invert, clause, *cond, &block|
          if i18n_keys = attributes_extractor.call(cond.first)
            cond = cond.first.dup
            i18n_nulls = i18n_keys.select { |key| cond[key].nil? }
            i18n_keys.each { |attr| cond[::Sequel[:"#{attr}_#{association_name}"][:value]] = cond.delete(attr) }
            super(invert, clause, cond, &block).
              send("join_#{association_name}", *(i18n_keys - i18n_nulls)).
              send("join_#{association_name}", *i18n_nulls, outer_join: true)
          else
            super(invert, clause, *cond, &block)
          end
        end
        private :_filter_or_exclude

        define_method :invert do
          if opts[:join] && (translation_joins = opts[:join].to_a.select { |join| join.table == translations_class.table_name }).present?
            translation_joins.each do |join|
              # We invert the join type when we invert the relation, so if we had a LEFT OUTER join, we
              # change it to an inner join, and vice versa. There should be a better way to do this...
              # TODO: Find a better way to do this.
              join.instance_variable_get(:@join_type) == :left_outer ?
                join.instance_variable_set(:@join_type, :inner) :
                join.instance_variable_set(:@join_type, :left_outer)
            end
          end
          super()
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
