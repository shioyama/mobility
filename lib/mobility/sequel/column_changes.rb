module Mobility
  module Sequel
    class ColumnChanges < Module
      def initialize(attributes)
        @attributes = attributes

        define_method :mobility_set do |attribute, value, locale: Mobility.locale|
          if attributes.include?(attribute)
            column = :"#{attribute}_#{locale}"
            @changed_columns << column if !changed_columns.include?(column) && (mobility_get(attribute) != value)
          end
          super(attribute, value, locale: locale)
        end
        private :mobility_set
      end
    end
  end
end
