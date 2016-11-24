require 'request_store'
require 'active_record'
require 'mobility/version'

module Mobility
  autoload :Configuration, "mobility/configuration"

  class << self
    def locale
      read_locale || I18n.locale
    end

    def locale=(locale)
      set_locale(locale)
    end

    def with_locale(locale)
      previous_locale = read_locale
      begin
        set_locale(locale)
        yield(locale)
      ensure
        set_locale(previous_locale)
      end
    end

    def storage
      RequestStore.store
    end

    def config
      storage[:mobility_configuration] ||= Mobility::Configuration.new
    end
    delegate :default_fallbacks, to: :config

    protected

    def read_locale
      storage[:mobility_locale]
    end

    def set_locale(locale)
      locale = locale.try(:to_sym)
      raise Mobility::InvalidLocale.new(locale) unless I18n.available_locales.include?(locale) || locale.nil?
      storage[:mobility_locale] = locale.try(:to_sym)
    end
  end
end
