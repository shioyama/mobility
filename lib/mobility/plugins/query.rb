# frozen_string_literal: true
module Mobility
  module Plugins
=begin

@see {Mobility::Plugins::ActiveRecord::Query}

=end
    module Query
      extend Plugin

      # Applies query plugin to attributes.
      included_hook do |model_class, backend_class, query: true|
        if query
          include_query_module(model_class, backend_class)
        end
      end

      private

      def include_query_module(model_class, backend_class)
        if Loaded::ActiveRecord && model_class < ::ActiveRecord::Base
          require "mobility/plugins/active_record/query"
          ActiveRecord::Query.apply(names, model_class, backend_class)
        elsif Loaded::Sequel && model_class < ::Sequel::Model
          require "mobility/plugins/sequel/query"
          Sequel::Query.apply(model_class)
        end
      end
    end
  end
end
