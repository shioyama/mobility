module Mobility
  class BackendResetter < Module
    def initialize(backend_reset_method, attributes)
      @model_reset_method = model_reset_method = Proc.new do
        attributes.each do |attribute|
          send("#{attribute}_translations").send(backend_reset_method)
        end
      end

      %i[changes_applied clear_changes_information].each do |method|
        define_method method do
          super()
          instance_eval &model_reset_method
        end
      end
    end

    def included(model_class)
      if model_class < ::ActiveRecord::Base
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
