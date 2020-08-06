# frozen_string_literal: true
module Mobility
  module Plugins
=begin

@see {Mobility::Plugins::ActiveRecord::Query} or {Mobility::Plugins::Sequel::Query}.

=end
    module Query
      extend Plugin

      default :i18n
      requires :backend, include: :before

      def query_method
        (options[:query] == true) ? self.class.defaults[:query] : options[:query]
      end
    end

    register_plugin(:query, Query)
  end
end
