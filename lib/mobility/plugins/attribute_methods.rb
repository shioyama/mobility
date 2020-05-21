module Mobility
  module Plugins
=begin

Adds translated attribute names and values to the hash returned by #attributes.
Also adds a method #translated_attributes with names and values of translated
attributes only.

@note Adding translated attributes to +attributes+ can have unexpected
  consequences, since these attributes do not have corresponding columns in the
  model table. Using this plugin may lead to conflicts with other gems.

=end
    module AttributeMethods
      extend Plugin

      # Applies attribute_methods plugin for a given option value.
      included_hook do |model_class, attribute_methods: nil|
        if attribute_methods
          include_attribute_methods_module(model_class, *names)
        end
      end

      private

      def include_attribute_methods_module(model_class, *attribute_names)
        module_builder =
          if Loaded::ActiveRecord && model_class.ancestors.include?(::ActiveRecord::AttributeMethods)
            require "mobility/plugins/active_record/attribute_methods_builder"
            Plugins::ActiveRecord::AttributeMethodsBuilder
          else
            raise ArgumentError, "#{model_class} does not support AttributeMethods plugin."
          end
        model_class.include module_builder.new(*attribute_names)
      end
    end
  end
end
