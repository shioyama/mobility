module Mobility
  module Plugins
    module ActiveRecord
      module Backend
        extend Plugin

        depends_on :backend, include: :before

        def load_backend(backend)
          if Symbol === backend
            require "mobility/backends/active_record/#{backend}"
            Backends.load_backend("active_record_#{backend}".to_sym)
          else
            super
          end
        rescue LoadError => e
          raise unless e.message =~ /active_record\/#{backend}/
          super
        end
      end
    end

    register_plugin(:active_record_backend, ActiveRecord::Backend)
  end
end
