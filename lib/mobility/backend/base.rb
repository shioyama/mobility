module Mobility
  module Backend
    module Base
      attr_reader :attribute, :model, :options

      def initialize(model, attribute, options = {})
        @model = model
        @attribute = attribute
        @options = options
      end
    end
  end
end
