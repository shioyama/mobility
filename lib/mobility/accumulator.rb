module Mobility
=begin

Class to access Mobility across backends. In particular, keeps a record of
which {Attributes} modules have been included on the model class.

=end
  class Accumulator
    # @return [Array<Attributes>]
    attr_reader :modules

    # @param [Class] model_class Model class
    def initialize
      @modules = []
    end

    # @return [Array<String>] Translated attributes defined on model
    def translated_attribute_names
      modules.map(&:names).flatten
    end

    # Appends backend module to +modules+ array for later reference.
    # @param [Attributes] backend_module Attributes module
    def << backend_module
      modules << backend_module
    end

    def initialize_dup(other)
      @modules = other.modules.dup
      super
    end
  end
end
