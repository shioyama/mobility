# frozen_string_literal: true
module Mobility
  module Plugins
=begin

@see {Mobility::Plugins::ActiveRecord::Query}

=end
    module Query
      extend Plugin

      depends_on :backend, include: :before

      # Applies query plugin to attributes.
      included_hook do |model_class, backend_class, query: true|
        delegate_included(:query, model_class, backend_class) if query
      end
    end

    register_plugin(:query, Query)
  end
end
