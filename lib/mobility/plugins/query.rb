# frozen_string_literal: true
module Mobility
  module Plugins
=begin

@see {Mobility::Plugins::ActiveRecord::Query}

=end
    module Query
      extend Plugin

      default true
      depends_on :backend, include: :before
    end

    register_plugin(:query, Query)
  end
end
