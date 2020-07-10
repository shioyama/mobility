# frozen_string_literal: true
require 'i18n'
require 'request_store'
require 'mobility/version'

=begin

Mobility is a gem for storing and retrieving localized data through attributes
on a class. The {Mobility} module includes all necessary methods and modules to
support defining backend accessors on a class.

To enable Mobility on a class, simply include or extend the {Mobility} module,
and define any attribute accessors using {Translates#mobility_accessor} (aliased to the
value of {Mobility.accessor_method}, which defaults to +translates+).

  class MyClass
    extend Mobility
    translates :title, backend: :key_value
  end

=end
module Mobility
  # A generic exception used by Mobility.
  class Error < StandardError
  end

  require "mobility/backend"
  require "mobility/backends"
  require "mobility/configuration"
  require "mobility/fallbacks"
  require "mobility/plugin"
  require "mobility/plugins"
  require "mobility/attributes"
  require "mobility/translates"

  # General error for version compatibility conflicts
  class VersionNotSupportedError < ArgumentError; end
  CALL_COMPILABLE_REGEXP = /\A[a-zA-Z_]\w*[!?]?\z/
  private_constant :CALL_COMPILABLE_REGEXP

  require "rails/generators/mobility/generators" if defined?(Rails)

  class << self
    def extended(model_class)
      return if model_class.respond_to? :mobility_accessor

      model_class.extend Translates
      model_class.extend ClassMethods

      if translates = Mobility.config.accessor_method
        model_class.singleton_class.send(:alias_method, translates, :mobility_accessor)
      end
    end

    # Extends model with this class so that +include Mobility+ is equivalent to
    # +extend Mobility+ (but +extend+ is preferred).
    # @param model_class
    def included(model_class)
      model_class.extend self
    end

    # @!group Locale Accessors
    # @return [Symbol] Mobility locale
    def locale
      read_locale || I18n.locale
    end

    # Sets Mobility locale
    # @param [Symbol] locale Locale to set
    # @raise [InvalidLocale] if locale is nil or not in
    #   +Mobility.available_locales+ (if +I18n.enforce_available_locales+ is +true+)
    # @return [Symbol] Locale
    def locale=(locale)
      set_locale(locale)
    end

    # Sets Mobility locale around block
    # @param [Symbol] locale Locale to set in block
    # @yield [Symbol] Locale
    def with_locale(locale)
      previous_locale = read_locale
      begin
        set_locale(locale)
        yield(locale)
      ensure
        set_locale(previous_locale)
      end
    end
    # @!endgroup

    # @return [RequestStore] Request store
    def storage
      RequestStore.store
    end

    # @!group Configuration Methods
    # @return [Mobility::Configuration] Mobility configuration
    def config
      @configuration ||= Configuration.new
    end

    # (see Mobility::Configuration#accessor_method)
    # @!method accessor_method
    #
    # (see Mobility::Configuration#query_method)
    # @!method query_method

    # (see Mobility::Configuration#new_fallbacks)
    # @!method new_fallbacks

    # (see Mobility::Configuration#default_backend)
    # @!method default_backend

    # (see Mobility::Configuration#plugins)
    # @!method plugins
    #
    # (see Mobility::Configuration#default_accessor_locales)
    # @!method default_accessor_locales
    %w[accessor_method query_method default_backend plugins default_accessor_locales].each do |method_name|
      define_method method_name do
        config.public_send(method_name)
      end
    end

    def new_fallbacks(*args)
      config.public_send(:new_fallbacks, *args)
    end

    # Configure Mobility
    # @yield [Mobility::Configuration] Mobility configuration
    def configure
      yield config
    end
    # @!endgroup

    # Return normalized locale
    # @param [String,Symbol] locale
    # @return [String] Normalized locale
    # @example
    #   Mobility.normalize_locale(:ja)
    #   #=> "ja"
    #   Mobility.normalize_locale("pt-BR")
    #   #=> "pt_br"
    def normalize_locale(locale = Mobility.locale)
      "#{locale.to_s.downcase.tr("-", "_")}"
    end
    alias_method :normalized_locale, :normalize_locale

    # Return normalized locale accessor name
    # @param [String,Symbol] attribute
    # @param [String,Symbol] locale
    # @return [String] Normalized locale accessor name
    # @raise [ArgumentError] if generated accessor has an invalid format
    # @example
    #   Mobility.normalize_locale_accessor(:foo, :ja)
    #   #=> "foo_ja"
    #   Mobility.normalize_locale_accessor(:bar, "pt-BR")
    #   #=> "bar_pt_br"
    def normalize_locale_accessor(attribute, locale = Mobility.locale)
      "#{attribute}_#{normalize_locale(locale)}".tap do |accessor|
        unless CALL_COMPILABLE_REGEXP.match(accessor)
          raise ArgumentError, "#{accessor.inspect} is not a valid accessor"
        end
      end
    end

    # Raises InvalidLocale exception if the locale passed in is present but not available.
    # @param [String,Symbol] locale
    # @raise [InvalidLocale] if locale is present but not available
    def enforce_available_locales!(locale)
      raise Mobility::InvalidLocale.new(locale) unless (locale.nil? || available_locales.include?(locale.to_sym))
    end

    # Returns available locales. Defaults to I18n.available_locales, but will
    # use Rails.application.config.i18n.available_locales if Rails is loaded
    # and config is non-nil.
    # @return [Array<Symbol>] Available locales
    # @note The special case for Rails is necessary due to the fact that Rails
    #   may load the model before setting +I18n.available_locales+. If we
    #   simply default to +I18n.available_locales+, we may define many more
    #   methods (in LocaleAccessors) than is really necessary.
    def available_locales
      if defined?(Rails) && Rails.application
        Rails.application.config.i18n.available_locales || I18n.available_locales
      else
        I18n.available_locales
      end
    end

    protected

    def read_locale
      storage[:mobility_locale]
    end

    def set_locale(locale)
      locale = locale.to_sym if locale
      enforce_available_locales!(locale) if I18n.enforce_available_locales
      storage[:mobility_locale] = locale
    end
  end

  module ClassMethods
    # Return translated attribute names on this model.
    # @return [Array<String>] Attribute names
    def mobility_attribute?(_)
      false
    end
  end

  class InvalidLocale < I18n::InvalidLocale; end
  class NotImplementedError < StandardError; end
end
