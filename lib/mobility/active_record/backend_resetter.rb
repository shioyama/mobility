# frozen_string_literal: true
require "mobility/active_model/backend_resetter"

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

        mod = Module.new do
          define_method :reload do |*args|
            super(*args).tap { instance_eval(&model_reset_method) }
          end
        end
        model_class.include mod
      end
    end
  end
end
