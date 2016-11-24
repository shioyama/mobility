module Mobility
  class Wrapper < SimpleDelegator
    attr_reader :modules
    alias :model_class :__getobj__

    def initialize(model_class)
      super
      @modules = []
    end

    def translated_attribute_names
      modules.map(&:attributes).flatten
    end

    def << backend_module
      modules << backend_module
    end
  end
end
