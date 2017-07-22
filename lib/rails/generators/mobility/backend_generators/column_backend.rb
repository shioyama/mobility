# frozen-string-literal: true
require "rails/generators"

module Mobility
  module BackendGenerators
    class ColumnBackend < Mobility::BackendGenerators::Base
      source_root File.expand_path("../../templates", __FILE__)

      def initialize(*args)
        super
        check_data_source!
      end
    end
  end
end
