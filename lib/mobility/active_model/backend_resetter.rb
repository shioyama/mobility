module Mobility
  module ActiveModel
=begin

Backend resetter for ActiveModel models. Adds hook to reset backend when
+changes_applied+ or +clear_changes_information+ methods are called on model.

=end
    class BackendResetter < Mobility::BackendResetter

      # (see Mobility::BackendResetter#initialize)
      def initialize(attribute_names)
        super

        model_reset_method = @model_reset_method

        %i[changes_applied clear_changes_information].each do |method|
          define_method method do
            super()
            instance_eval(&model_reset_method)
          end
        end
      end
    end
  end
end
