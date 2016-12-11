module Mobility
  class BackendResetter < Module
    def initialize(backend_reset_method, attributes)
      @model_reset_method = Proc.new do
        attributes.each do |attribute|
          mobility_backend_for(attribute).send(backend_reset_method)
        end
      end
    end

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
