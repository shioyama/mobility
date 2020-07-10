module Mobility
  module Plugins
    module Sequel
      module Backend
        extend Plugin

        depends_on :backend, include: :before

        def load_backend(backend)
          if Symbol === backend
            require "mobility/backends/sequel/#{backend}"
            Backends.load_backend("sequel_#{backend}".to_sym)
          else
            super
          end
        rescue LoadError => e
          raise unless e.message =~ /sequel\/#{backend}/
          super
        end
      end
    end

    register_plugin(:sequel_backend, Sequel::Backend)
  end
end
