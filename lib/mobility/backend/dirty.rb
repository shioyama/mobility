module Mobility
  module Backend
=begin

Dirty tracking for Mobility attributes. See class-specific implementations for
details.

@see Mobility::Backend::ActiveModel::Dirty
@see Mobility::Backend::Sequel::Dirty

@note Dirty tracking can have unexpected results when combined with fallbacks.
  A change in the fallback locale value will not mark an attribute falling
  through to that locale as changed, even though it may look like it has
  changed. However, when the value for the current locale is changed from nil
  or blank to a new value, the change will be recorded as a change from that
  fallback value, rather than from the nil or blank value. The specs are the
  most reliable source of information on the interaction between dirty tracking
  and fallbacks.

=end
    module Dirty
      class << self
        # Applies dirty option module to attributes for a given option value.
        # @param [Attributes] attributes
        # @param [Boolean] option Value of option
        # @raise [ArgumentError] if model class does not support dirty tracking
        def apply(attributes, option)
          if option
            FallthroughAccessors.apply(attributes, true)
            include_dirty_module(attributes.backend_class, attributes.model_class, *attributes.names)
          end
        end

        private

        def include_dirty_module(backend_class, model_class, *attribute_names)
          dirty_module =
            if Loaded::ActiveRecord && model_class.ancestors.include?(::ActiveModel::Dirty)
              (model_class < ::ActiveRecord::Base) ?
                Backend::ActiveRecord::Dirty : Backend::ActiveModel::Dirty
            elsif Loaded::Sequel && model_class < ::Sequel::Model
              Backend::Sequel::Dirty
            else
              raise ArgumentError, "#{model_class} does not support Dirty module."
            end
          backend_class.include dirty_module
          model_class.include dirty_module.const_get(:MethodsBuilder).new(*attribute_names)
        end
      end
    end
  end
end
