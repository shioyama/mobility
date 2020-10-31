module Mobility
  module Backends
    @backends = {}

    class << self
      # @param [Symbol, Object] backend Name of backend to load.
      def load_backend(name)
        return name if Module === name || name.nil?

        unless (backend = @backends[name])
          require "mobility/backends/#{name}"
          raise LoadError, "backend #{name} did not register itself correctly in Mobility::Backends" unless (backend = @backends[name])
        end
        backend
      end
    end

    def self.register_backend(name, mod)
      @backends[name] = mod
    end

    class LoadError < Error; end
  end
end
