# frozen_string_literal: true
require "mobility/active_model/backend_resetter"

module Mobility
  module ActiveRecord
=begin

Backend resetter for ActiveRecord models. Adds hook on +reload+ event to
{Mobility::ActiveModel::BackendResetter}.

=end
    class BackendResetter < Mobility::ActiveModel::BackendResetter

      # (see Mobility::BackendResetter#initialize)
      def initialize(attribute_names, &block)
        super

        model_reset_method = @model_reset_method

        define_method :reload do |*args|
          super(*args).tap { instance_eval(&model_reset_method) }
        end
      end
    end
  end
end
