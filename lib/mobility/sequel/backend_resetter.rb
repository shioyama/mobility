module Mobility
  module Sequel
=begin

Backend resetter for Sequel models. Triggers backend reset when +refresh+
method is called.

=end
    class BackendResetter < Mobility::BackendResetter

      # @param [Class] model_class Class of model to which backend resetter will be applied
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
