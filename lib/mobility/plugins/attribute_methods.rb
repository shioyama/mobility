module Mobility
  module Plugins
=begin

Adds translated attribute names and values to the hash returned by #attributes.
Also adds a method #translated_attributes with names and values of translated
attributes only.

@note Adding translated attributes to #attributes can have unexpected
  consequences, since these values are not true attribute values.

=end
    module AttributeMethods
      class << self
        # Applies attribute_methods plugin for a given option value.
        # @param [Attributes] attributes
        # @param [Boolean] option Value of option
        # @raise [ArgumentError] if model class does not support dirty tracking
        def apply(attributes, option)
          if option
            include_attribute_methods_module(attributes.model_class, *attributes.names)
          end
        end

        private

        def include_attribute_methods_module(model_class, *attribute_names)
          module_builder =
            if Loaded::ActiveRecord && model_class.ancestors.include?(::ActiveRecord::AttributeMethods)
              require "mobility/plugins/active_record/attribute_methods"
              Plugins::ActiveRecord::AttributeMethods
            else
              raise ArgumentError, "#{model_class} does not support AttributeMethods plugin."
            end
          model_class.include module_builder.new(*attribute_names)
        end
      end
    end
  end
end
