module Mobility
  module Backend
    class Sequel::KeyValue::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **options)
        super
        association_name, translation_class = options[:association_name], options[:class_name]

        define_join_method(association_name, translation_class)
        define_query_methods(association_name)

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(attribute => value).select_all(model.table_name).first
          end
        end
      end

      private

      def define_join_method(association_name, translation_class)
        define_method :"join_#{association_name}" do |*attributes, **options|
          attributes.inject(self) do |relation, attribute|
            join_type = options[:outer_join] ? :left_outer : :inner
            relation.join_table(join_type,
                                translation_class.table_name,
                                {
                                  key: attribute.to_s,
                                  locale: Mobility.locale.to_s,
                                  translatable_type: model.name,
                                  translatable_id: ::Sequel[:"#{model.table_name}"][:id]
                                },
                                table_alias: "#{attribute}_#{association_name}")
          end
        end
      end

      def define_query_methods(association_name)
        # TODO: find a better way to do this that doesn't involve overriding
        # a private method...
        #
        attributes_extractor = @attributes_extractor

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

      end
    end
  end
end
