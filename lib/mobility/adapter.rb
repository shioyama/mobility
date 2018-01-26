module Mobility
=begin

Provides interface to access attributes across all backends of an instance.

=end
  class Adapter
    # @param [Object] model Instance of model class
    def initialize(model)
      @model = model
    end

    # Fetch backend for an attribute
    # @param [String] attribute Attribute
    def backend_for(attribute)
      @model.send(Backend.method_name(attribute))
    end
  end
end
