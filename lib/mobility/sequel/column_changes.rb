module Mobility
  module Sequel
=begin

Internal class used to force Sequel model to notice changes when +mobility_set+
is called.

=end
    class ColumnChanges < Module
      # @param [Array<String>] attributes Backend attributes
      def initialize(attributes)
        @attributes = attributes

        define_method :mobility_set do |attribute, value, locale: Mobility.locale|
          if attributes.include?(attribute)
            column = attribute.to_sym
            column_with_locale = :"#{attribute}_#{locale}"
            if mobility_get(attribute) != value
              @changed_columns << column_with_locale if !changed_columns.include?(column_with_locale)
              @changed_columns << column             if !changed_columns.include?(column)
            end
          end
          super(attribute, value, locale: locale)
        end
        private :mobility_set
      end
    end
  end
end
