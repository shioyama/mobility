module Mobility
  module Backend
    module Sequel
      class QueryMethods < Module
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
