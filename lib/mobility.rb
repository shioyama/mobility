require 'i18n'
require 'request_store'
require 'mobility/version'

%w[object nil string].each do |type|
  begin
    require "active_support/core_ext/#{type}"
  rescue LoadError
    require "mobility/core_ext/#{type}"
  end
end

module Mobility
  autoload :Attributes,       "mobility/attributes"
  autoload :Backend,          "mobility/backend"
  autoload :BackendResetter,  "mobility/backend_resetter"
  autoload :Configuration,    "mobility/configuration"
  autoload :InstanceMethods,  "mobility/instance_methods"
  autoload :Translates,       "mobility/translates"
  autoload :Wrapper,          "mobility/wrapper"

  require "mobility/orm"

  # General error for version compatibility conflicts
  class VersionNotSupportedError < ArgumentError; end

  begin
    require "active_record"
    raise VersionNotSupportedError, "Mobility is only compatible with ActiveRecord 5.0 and greater" if ::ActiveRecord::VERSION::MAJOR < 5
    autoload :ActiveModel,      "mobility/active_model"
    autoload :ActiveRecord,     "mobility/active_record"
    Loaded::ActiveRecord = true
  rescue LoadError
    Loaded::ActiveRecord = false
  end

  begin
    require "rails"
    autoload :InstallGenerator, "generators/mobility/install_generator"
    Loaded::Rails = true
  rescue LoadError
    class InstallGenerator; end
    Loaded::Rails = false
  end

  begin
    require "sequel"
    raise VersionNotSupportedError, "Mobility is only compatible with Sequel 4.0 and greater" if ::Sequel::MAJOR < 4
    require "sequel/extensions/inflector"
    require "sequel/plugins/dirty"
    autoload :Sequel, "mobility/sequel"
    Loaded::Sequel = true
  rescue LoadError
    Loaded::Sequel = false
  end

  class << self
    def extended(model_class)
      return if model_class.respond_to? :translation_accessor
      model_class.class_eval do
        def self.mobility
          @mobility ||= Mobility::Wrapper.new(self)
        end
        def self.translated_attribute_names
          mobility.translated_attribute_names
        end

        extend Translates
      end

      model_class.include(InstanceMethods)

      if Loaded::ActiveRecord
        model_class.include(ActiveRecord)                   if model_class < ::ActiveRecord::Base
        model_class.include(ActiveModel::AttributeMethods)  if model_class.ancestors.include?(::ActiveModel::AttributeMethods)
      end

      if Loaded::Sequel
        model_class.include(Sequel) if model_class < ::Sequel::Model
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
    %w[default_fallbacks default_backend default_accessor_locales].each do |method_name|
      define_method method_name do
        config.public_send(method_name)
      end
    end

    def configure
      yield config
    end

    def normalize_locale(locale)
      "#{locale.to_s.downcase.sub("-", "_")}"
    end

    protected

    def read_locale
      storage[:mobility_locale]
    end

    def set_locale(locale)
      locale = locale.to_sym if locale
      raise Mobility::InvalidLocale.new(locale) unless I18n.available_locales.include?(locale) || locale.nil?
      storage[:mobility_locale] = locale
    end
  end

  class BackendRequired < ArgumentError; end
  class InvalidLocale < I18n::InvalidLocale; end
end
