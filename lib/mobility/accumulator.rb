module Mobility
=begin

Class to access Mobility across backends. In particular, keeps a record of
which {Attributes} modules have been included on the model class.

=end
  class Accumulator
    # @return [Array<Attributes>]
    attr_reader :modules

    # Map from attribute name to backend class
    # @return [Hash]
    attr_reader :backends

    # @param [Class] model_class Model class
    def initialize
      @modules  = []
      @backends = {}
    end

    # @return [Array<String>] Translated attributes defined on model
    def translated_attribute_names
      modules.map(&:names).flatten
    end

    # Appends backend module to +modules+ array for later reference.
    # @param [Attributes] backend_module Attributes module
    def << backend_module
      modules << backend_module
      backend_module.names.each { |name| backends[name.to_sym] = backend_module.backend_class }
    end

    def initialize_dup(other)
      @modules = other.modules.dup
      super
    end
  end
end
