module Mobility
=begin

Class to access Mobility across backends. In particular, keeps a record of
which {Attributes} modules have been included on the model class. It is also a
simple delegator, so any missing method will be delegated to the model class.

=end
  class Wrapper < SimpleDelegator
    # @return [Array<Attributes>]
    attr_reader :modules
    alias :model_class :__getobj__

    # @param [Class] model_class Model class
    def initialize(model_class)
      super
      @modules = []
    end

    # @return [Array<String>] Translated attributes defined on model
    def translated_attribute_names
      modules.map(&:attributes).flatten
    end

    # Appends backend module to +modules+ array for later reference.
    # @param [Attributes] backend_module Attributes module
    def << backend_module
      modules << backend_module
    end
  end
end
