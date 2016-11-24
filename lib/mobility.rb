require 'request_store'
require 'active_record'
require 'mobility/version'

module Mobility
  autoload :Configuration, "mobility/configuration"

  class << self
    def storage
      RequestStore.store
    end

    def config
      storage[:mobility_configuration] ||= Mobility::Configuration.new
    end
    delegate :default_fallbacks, to: :config
  end
end
