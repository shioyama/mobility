module Mobility
=begin

Instance methods attached to all model classes when model includes or extends
{Mobility}.

=end
  module InstanceMethods
    # Fetch backend for an attribute
    # @param [String] attribute Attribute
    def mobility_backend_for(attribute)
      send(Backend.method_name(attribute))
    end
  end
end
