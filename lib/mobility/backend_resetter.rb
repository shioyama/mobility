module Mobility
=begin

Resets backend cache when reset events occur.

@see Mobility::ActiveRecord::BackendResetter
@see Mobility::ActiveModel::BackendResetter
@see Mobility::Sequel::BackendResetter

=end
  class BackendResetter < Module
    # @param [Symbol] backend_reset_method Name of method to be called on
    #   backend(s) to perform reset
    # @param [Array<String>] attributes Attributes whose backends should be reset
    def initialize(backend_reset_method, attributes)
      @model_reset_method = Proc.new do
        attributes.each do |attribute|
          mobility_backend_for(attribute).send(backend_reset_method)
        end
      end
    end

    # Returns backend resetter class for model class
    # @param [Class] model_class Class of model to which backend resetter will be applied
    def self.for(model_class)
      if Loaded::ActiveRecord && model_class < ::ActiveRecord::Base
        ActiveRecord::BackendResetter
      elsif Loaded::ActiveRecord && model_class.ancestors.include?(::ActiveModel::Dirty)
        ActiveModel::BackendResetter
      elsif Loaded::Sequel && model_class < ::Sequel::Model
        Sequel::BackendResetter
      else
        self
      end
    end
  end
end
