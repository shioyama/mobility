module Mobility
  module ActiveModel
    class BackendResetter < Mobility::BackendResetter
      def initialize(backend_reset_method, attributes)
        super

        model_reset_method = @model_reset_method

        %i[changes_applied clear_changes_information].each do |method|
          define_method method do
            super()
            instance_eval &model_reset_method
          end
        end
      end
    end
  end
end
