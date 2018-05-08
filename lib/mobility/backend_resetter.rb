# frozen_string_literal: true

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
    # @param [Array<String>] attribute_names Names of attributes whose backends should be reset
    # @yield Backend to reset as context for block
    # @raise [ArgumentError] if no block is provided.
    def initialize(attribute_names, &block)
      raise ArgumentError, "block required" unless block_given?
      names = attribute_names.map(&:to_sym)
      @model_reset_method = Proc.new do
        names.each do |name|
          if @mobility_backends && @mobility_backends[name]
            @mobility_backends[name].instance_eval(&block)
          end
        end
      end
    end

    # Returns backend resetter class for model class
    # @param [Class] model_class Class of model to which backend resetter will be applied
    def self.for(model_class)
      if Loaded::ActiveRecord && model_class < ::ActiveRecord::Base
        require "mobility/active_record/backend_resetter"
        ActiveRecord::BackendResetter
      elsif Loaded::ActiveRecord && model_class.ancestors.include?(::ActiveModel::Dirty)
        require "mobility/active_model/backend_resetter"
        ActiveModel::BackendResetter
      elsif Loaded::Sequel && model_class < ::Sequel::Model
        require "mobility/sequel/backend_resetter"
        Sequel::BackendResetter
      else
        self
      end
    end
  end
end
