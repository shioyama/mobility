# frozen_string_literal: true

module Mobility
  module Plugins
    module ColumnFallback
      extend Plugin

      default false

      requires :backend, include: :before
    end

    register_plugin(:column_fallback, ColumnFallback)
  end
end
