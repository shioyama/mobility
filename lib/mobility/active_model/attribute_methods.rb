module Mobility
  module ActiveModel
=begin

Included into model if model has +ActiveModel::AttributeMethods+ among its
ancestors.

=end
    module AttributeMethods
      delegate :translated_attribute_names, to: :class

      # Adds translated attributes to +attributes+.
      # @return [Array<String>] Model attributes
      def attributes
        super.merge(translated_attributes)
      end

      # Translated attributes defined on model.
      # @return [Array<String>] Translated attributes
      def translated_attributes
        translated_attribute_names.inject({}) do |attributes, name|
          attributes.merge(name.to_s => send(name))
        end
      end
    end
  end
end
