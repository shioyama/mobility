# frozen-string-literal: true
require "rails/generators"

module Mobility
  module BackendGenerators
    class HstoreBackend < Mobility::BackendGenerators::Base
      source_root File.expand_path("../../templates", __FILE__)
    end
  end
end
