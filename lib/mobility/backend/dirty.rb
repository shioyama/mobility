module Mobility
  module Backend
=begin

Dirty tracking for Mobility attributes. See class-specific implementations for
details.

@see Mobility::Backend::ActiveModel::Dirty
@see Mobility::Backend::Sequel::Dirty

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
