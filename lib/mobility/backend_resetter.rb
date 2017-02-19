module Mobility
=begin

Resets backend cache when reset events occur.

@example Add trigger to call a method +my_backend_reset_method+ on backend instance when reset event(s) occurs on model
  resetter = Mobility::BackendResetter.for(MyModel).new(attributes) { my_backend_reset_method }
  MyModel.include(resetter)

@see Mobility::ActiveRecord::BackendResetter
@see Mobility::ActiveModel::BackendResetter
@see Mobility::Sequel::BackendResetter

=end
  class BackendResetter < Module
    # @param [Array<String>] attributes Attributes whose backends should be reset
    # @yield Backend to reset as context for block
    # @raise [ArgumentError] if no block is provided.
    def initialize(attributes, &block)
      raise ArgumentError, "block required" unless block_given?
      @model_reset_method = Proc.new do
        attributes.each do |attribute|
          if @mobility_backends && @mobility_backends[attribute]
            @mobility_backends[attribute].instance_eval &block
          end
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
