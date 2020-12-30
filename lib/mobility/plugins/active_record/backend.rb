# frozen-string-literal: true

module Mobility
  module Plugins
    module ActiveRecord
=begin

Maps backend names to ActiveRecord namespaced backends.

=end
      module Backend
        extend Plugin

        requires :backend, include: :before

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
