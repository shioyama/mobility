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

      default true
      requires :attributes

      initialize_hook do |*names|
        include InstanceMethods

        define_method :translated_attributes do
          super().merge(names.inject({}) do |attributes, name|
            attributes.merge(name.to_s => send(name))
          end)
        end
      end

      # Applies attribute_methods plugin for a given option value.
      included_hook do
        if options[:attribute_methods]
          define_method :untranslated_attributes, ::ActiveRecord::Base.instance_method(:attributes)
        end
      end

      module InstanceMethods
        def translated_attributes
          {}
        end

        def attributes
          super.merge(translated_attributes)
        end
      end
    end

    register_plugin(:attribute_methods, AttributeMethods)
  end
end
