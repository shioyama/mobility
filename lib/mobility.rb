# frozen_string_literal: true
require 'i18n'
require 'request_store'
require 'mobility/version'

=begin

Mobility is a gem for storing and retrieving localized data through attributes
on a class. The {Mobility} module includes all necessary methods and modules to
support defining backend accessors on a class.

To enable Mobility on a class, simply include or extend the {Mobility} module,
and define any attribute accessors using {Translates#translates}.

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
  require "mobility/plugin"
  require "mobility/plugins"
  require "mobility/translations"

  # General error for version compatibility conflicts
  class VersionNotSupportedError < ArgumentError; end
  CALL_COMPILABLE_REGEXP = /\A[a-zA-Z_]\w*[!?]?\z/
  private_constant :CALL_COMPILABLE_REGEXP

  require "rails/generators/mobility/generators" if defined?(Rails)

  class << self
    def extended(model_class)
      def model_class.translates(*args, **options)
        include Mobility.translations_class.new(*args, **options)
      end
    end

    # Extends model with this class so that +include Mobility+ is equivalent to
    # +extend Mobility+ (but +extend+ is preferred).
    # @param model_class
    def included(model_class)
      model_class.extend self
    end

    # @return [Symbol,Class]
    def default_backend
      translations_class.defaults[:backend]
    end

    # Configure Mobility
    # @yield [Mobility::Translations]
    def configure(&block)
      translates_with(Class.new(Translations)) unless @translations_class
      if block.arity == 0
        translations_class.instance_exec(&block)
      else
        yield translations_class
      end
    end
    # @!endgroup

    def translates_with(pluggable)
      raise ArgumentError, "translations class must be a subclass of Module." unless Module === pluggable
      @translations_class = pluggable
    end

    def translations_class
      @translations_class ||
        raise(Error, "Mobility has not been configured. "\
              "Configure with Mobility.configure, or assign a translations class with Mobility.translates_with(<class>)")
    end

    def reset_translations_class
      @translations_class = nil
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

  class InvalidLocale < I18n::InvalidLocale; end
  class NotImplementedError < StandardError; end
end
