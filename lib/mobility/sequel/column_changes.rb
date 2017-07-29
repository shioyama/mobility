module Mobility
  module Sequel
=begin

Internal class used to force Sequel model to notice changes when mobility
setter method is called.

=end
    class ColumnChanges < Module
      # @param [Array<String>] attributes Backend attributes
      def initialize(attributes)
        @attributes = attributes

        attributes.each do |attribute|
          define_method "#{attribute}=".freeze do |value, **options|
            if !options[:super] && send(attribute) != value
              locale = options[:locale] || Mobility.locale
              column = attribute.to_sym
              column_with_locale = :"#{attribute}_#{Mobility.normalize_locale(locale)}"
              @changed_columns << column_with_locale if !changed_columns.include?(column_with_locale)
              @changed_columns << column             if !changed_columns.include?(column)
            end
            super(value, **options)
          end
        end
      end
    end
  end
end
