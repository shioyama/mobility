module Mobility
  class Configuration
    attr_accessor :accessor_method, :default_fallbacks, :default_backend, :default_accessor_locales

    def initialize
      @accessor_method = :translates
      @default_fallbacks = I18n::Locale::Fallbacks.new
      @default_accessor_locales = I18n.available_locales
    end
  end
end
