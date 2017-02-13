module Mobility
  module Backend
    module Sequel
=begin

Defines query method overrides to handle translated attributes for Sequel
models. For details see backend-specific subclasses.

=end
      class QueryMethods < Module
        # @param [Array<String>] attributes Translated attributes
        # @param [Hash] options Backend options
        def initialize(attributes, **options)
          @attributes = attributes.map! &:to_sym
          @attributes_extractor = lambda do |cond|
            cond.is_a?(Hash) && (cond.keys & attributes).presence
          end
        end
      end
    end
  end
end
