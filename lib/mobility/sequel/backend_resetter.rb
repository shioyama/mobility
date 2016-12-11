module Mobility
  module Sequel
    class BackendResetter < Mobility::BackendResetter
      def included(model_class)
        model_reset_method = @model_reset_method

        model_class.class_eval do
          mod = Module.new do
            define_method :refresh do
              super().tap { instance_eval &model_reset_method }
            end
          end
          include mod
        end
      end
    end
  end
end
