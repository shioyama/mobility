# frozen_string_literal: true

module Mobility
  module Plugins
    module OriginalColumn
      extend Plugin

      default false

      requires :backend, include: :before
    end

    register_plugin(:original_column, OriginalColumn)
  end
end
