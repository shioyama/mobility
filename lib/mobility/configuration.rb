module Mobility
  class Configuration
    attr_accessor :default_fallbacks, :default_backend, :default_accessor_locales

    def initialize
      @default_fallbacks = I18n::Locale::Fallbacks.new
      @default_accessor_locales = I18n.available_locales
    end
  end
end
