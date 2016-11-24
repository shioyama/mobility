require 'request_store'
require 'active_record'
require 'mobility/version'

module Mobility
  autoload :Attributes,    "mobility/attributes"
  autoload :Backend,       "mobility/backend"
  autoload :Configuration, "mobility/configuration"
  autoload :Translates,    "mobility/translates"

  class << self
    def extended(model_class)
      return if model_class.respond_to? :translation_accessor
      model_class.class_eval do
        extend Translates
      end
    end

    def included(model_class)
      model_class.extend self
    end

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

  class BackendRequired < ArgumentError; end
end
