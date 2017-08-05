require "mobility/util"

module Mobility
  module Backends
    module Sequel
=begin

Defines query method overrides to handle translated attributes for Sequel
models. For details see backend-specific subclasses.

=end
      class QueryMethods < Module
        # @param [Array<String>] attributes Translated attributes
        def initialize(attributes, _)
          @attributes = attributes.map!(&:to_sym)
          @attributes_extractor = lambda do |cond|
            cond.is_a?(Hash) && Util.presence(cond.keys & attributes)
          end
        end
      end
    end
  end
end
