module Mobility
  module Backend
    module Dirty
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
