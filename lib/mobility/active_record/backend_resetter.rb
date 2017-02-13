module Mobility
  module ActiveRecord
=begin

Backend resetter for ActiveRecord models. Adds hook on +reload+ event to
{Mobility::ActiveModel::BackendResetter}.

=end
    class BackendResetter < Mobility::ActiveModel::BackendResetter

      # @param [Class] model_class Class of model to which backend resetter will be applied
      def included(model_class)
        model_reset_method = @model_reset_method

        model_class.class_eval do
          mod = Module.new do
            define_method :reload do
              super().tap { instance_eval &model_reset_method }
            end
          end
          include mod
        end
      end
    end
  end
end
