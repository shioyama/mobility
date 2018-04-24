module Mobility
  module Sequel
=begin

Backend resetter for Sequel models. Triggers backend reset when +refresh+
method is called.

=end
    class BackendResetter < Mobility::BackendResetter

      # (see Mobility::BackendResetter#initialize)
      def initialize(attribute_names, &block)
        super

        model_reset_method = @model_reset_method

        define_method :refresh do
          super().tap { instance_eval(&model_reset_method) }
        end
      end
    end
  end
end
