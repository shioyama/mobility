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

When defining this module, Mobility attempts to +require+ various gems (for
example, +active_record+ and +sequel+) to evaluate which are loaded. Loaded
gems are tracked with dynamic subclasses of the {Loaded} module and referenced
in backends to define gem-dependent behavior.

=end
module Mobility
  require "mobility/attributes"
  require "mobility/backend"
  require "mobility/backends"
  require "mobility/backend_resetter"
  require "mobility/configuration"
  require "mobility/fallbacks"
  require "mobility/loaded"
  require "mobility/plugins"
  require "mobility/translates"

  # General error for version compatibility conflicts
  class VersionNotSupportedError < ArgumentError; end
  CALL_COMPILABLE_REGEXP = /\A[a-zA-Z_]\w*[!?]?\z/
  private_constant :CALL_COMPILABLE_REGEXP

  begin
    require "rails"
    Loaded::Rails = true
  rescue LoadError => e
    raise unless e.message =~ /rails/
    Loaded::Rails = false
  end

  begin
    require "active_record"
    raise VersionNotSupportedError, "Mobility is only compatible with ActiveRecord 4.2 and greater" if ::ActiveRecord::VERSION::STRING < "4.2"
    Loaded::ActiveRecord = true
  rescue LoadError => e
    raise unless e.message =~ /active_record/
    Loaded::ActiveRecord = false
  end

  if Loaded::ActiveRecord
    require "mobility/active_model"
    require "mobility/active_record"
    if Loaded::Rails
      require "rails/generators/mobility/generators"
    end
  end

  begin
    require "sequel"
    raise VersionNotSupportedError, "Mobility is only compatible with Sequel 4.0 and greater" if ::Sequel::MAJOR < 4
    require "sequel/plugins/mobility"
    #TODO avoid automatically including the inflector extension
    require "sequel/extensions/inflector"
    require "sequel/plugins/dirty"
    require "mobility/sequel"
    Loaded::Sequel = true
  rescue LoadError => e
    raise unless e.message =~ /sequel/
    Loaded::Sequel = false
  end

  class << self
    def extended(model_class)
      return if model_class.respond_to? :mobility_accessor

      model_class.extend Translates
      model_class.extend ClassMethods
      #TODO: Remove in v1.0
      model_class.include InstanceMethods

      if translates = Mobility.config.accessor_method
        model_class.singleton_class.send(:alias_method, translates, :mobility_accessor)
      end

      if Loaded::ActiveRecord && model_class < ::ActiveRecord::Base
        model_class.include(ActiveRecord)
      end

      if Loaded::Sequel && model_class < ::Sequel::Model
        model_class.include(Sequel)
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

    # @param [Class] parent_class Parent class in namespace
    # @param [Symbol] key Name of class to find in namespace
    # @return [Class] Class in namespace matching key
    # @api private
    def get_class_from_key(parent_class, key)
      klass_name = key.to_s.gsub(/(^|_)(.)/){|x| x[-1..-1].upcase}
      parent_class.const_get(klass_name)
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

    # (see Mobility::Configuration#default_options)
    # @!method default_options
    #
    # (see Mobility::Configuration#plugins)
    # @!method plugins
    #
    # (see Mobility::Configuration#default_accessor_locales)
    # @!method default_accessor_locales
    %w[accessor_method query_method default_backend default_options plugins default_accessor_locales].each do |method_name|
      define_method method_name do
        config.public_send(method_name)
      end
    end

    # TODO: Remove in v1.0
    def default_fallbacks(*args)
      config.public_send(:default_fallbacks, *args)
    end

    # TODO: Make private in v1.0
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
      # TODO: Remove conditional in v1.0
      if I18n.enforce_available_locales
        raise Mobility::InvalidLocale.new(locale) unless (locale.nil? || available_locales.include?(locale.to_sym))
      else
        warn <<-EOL
WARNING: You called Mobility.enforce_available_locales! in a situation where
I18n.enforce_available_locales is false. In the past, Mobility would do nothing
in this case, but as of the next major release Mobility will ignore the I18n
setting and enforce available locales whenever this method is called.
EOL
      end
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
      if Loaded::Rails && Rails.application
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

  # TODO: Remove entire module in v1.0
  module InstanceMethods
    # Fetch backend for an attribute
    # @deprecated Use mobility_backends[:<attribute>] instead.
    # @param [String] attribute Attribute
    def mobility_backend_for(attribute)
      warn %{
WARNING: mobility_backend_for is deprecated and will be removed in the next
version of Mobility. Use <post>.<attribute>_backend instead.}
      mobility_backends[attribute.to_sym]
    end

    def mobility
      warn %{
WARNING: <post>.mobility is deprecated and will be removed in the next
version of Mobility. To get backends, use <post>.<attribute>_backend instead.}
      @mobility ||= Adapter.new(self)
    end

    class Adapter < Struct.new(:model)
      def backend_for(attribute)
        model.mobility_backends[attribute.to_sym]
      end
    end
    private_constant :Adapter
  end

  module ClassMethods
    # Return translated attribute names on this model.
    # @return [Array<String>] Attribute names
    def mobility_attributes
      []
    end
  end

  class InvalidLocale < I18n::InvalidLocale; end
  class NotImplementedError < StandardError; end
end
