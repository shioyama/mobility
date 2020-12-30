module Mobility
  module Plugins
    module Sequel
=begin

Maps backend names to Sequel namespaced backends.

=end
      module Backend
        extend Plugin

        requires :backend, include: :before

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
