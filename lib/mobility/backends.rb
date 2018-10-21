module Mobility
  module Backends
    class << self
      # @param [Symbol, Object] backend Name of backend class to load, or
      #   backend class itself.
      def load_backend(backend)
        return backend if Module === backend
        require "mobility/backends/#{backend}"
        Mobility.get_class_from_key(self, backend)
      end
    end
  end
end
