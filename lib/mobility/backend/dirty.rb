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
      # @param model_class Class of model this backend is defined on.
      # @return [Backend]
      # @raise [ArgumentError] if model class does not support dirty tracking
      def self.for(model_class)
        model_class ||= Object
        if Loaded::ActiveRecord && model_class.ancestors.include?(::ActiveModel::Dirty)
          Backend::ActiveModel::Dirty
        elsif Loaded::Sequel && model_class < ::Sequel::Model
          Backend::Sequel::Dirty
        else
          raise ArgumentError, "#{model_class.to_s} does not support Dirty module."
        end
      end
    end
  end
end
