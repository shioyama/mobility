module Mobility
  module Backend
    class Sequel::Table::QueryMethods < Sequel::QueryMethods
      def initialize(_attributes, **options)
        attributes = _attributes.map &:to_sym
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

        define_method :where do |*cond, &block|
          if cond.first.is_a?(Hash) && (keys = cond.first.keys & attributes).present?
            cond = cond.first.dup
            null_keys = keys.select { |key| cond[key].nil? }
            keys.each { |attr| cond[::Sequel[:"#{attr}_#{association_name}"][:value]] = cond.delete(attr) }
            super(cond, &block).
              send("join_#{association_name}", *(keys - null_keys)).
              send("join_#{association_name}", *null_keys, outer_join: true)
          else
            super(*cond, &block)
          end
        end

        define_method :invert do
          if opts[:join] && (translation_joins = opts[:join].to_a.select { |join| join.table == translations_class.table_name }).present?
            # We need to actually update the exisiting mobility joins in-place to avoid issues,
            # but this is not nice.
            # TODO: Improve this.
            translation_joins.each { |join| join.instance_variable_set :@join_type, :inner }
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
