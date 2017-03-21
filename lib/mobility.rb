require 'i18n'
require 'request_store'
require 'mobility/version'

%w[object string].each do |type|
  begin
    require "active_support/core_ext/#{type}"
  rescue LoadError
    require "mobility/core_ext/#{type}"
  end
end

=begin

Mobility is a gem for storing and retrieving localized data through attributes
on a class. The {Mobility} module includes all necessary methods and modules to
support defining backend accessors on a class.

To enable Mobility on a class, simply include or extend the {Mobility} module,
and define any attribute accessors using {Translates#mobility_accessor} (aliased to the
value of {Mobility.accessor_method}, which defaults to +translates+).

  class MyClass
    include Mobility
    translates :title, backend: :key_value
  end

When defining this module, Mobility attempts to +require+ various gems (for
example, +active_record+ and +sequel+) to evaluate which are loaded. Loaded
gems are tracked with dynamic subclasses of the {Loaded} module and referenced
in backends to define gem-dependent behavior.

=end
module Mobility
  autoload :Attributes,           "mobility/attributes"
  autoload :Backend,              "mobility/backend"
  autoload :BackendResetter,      "mobility/backend_resetter"
  autoload :Configuration,        "mobility/configuration"
  autoload :FallthroughAccessors, "mobility/fallthrough_accessors"
  autoload :InstanceMethods,      "mobility/instance_methods"
  autoload :Translates,           "mobility/translates"
  autoload :Wrapper,              "mobility/wrapper"

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
    Loaded::Rails = true
    require "mobility/rails"
  rescue LoadError
    Loaded::Rails = false
  end

  begin
    require "sequel"
    raise VersionNotSupportedError, "Mobility is only compatible with Sequel 4.0 and greater" if ::Sequel::MAJOR < 4
    require "sequel/plugins/mobility"
    require "sequel/extensions/inflector"
    require "sequel/plugins/dirty"
    autoload :Sequel, "mobility/sequel"
    Loaded::Sequel = true
  rescue LoadError
    Loaded::Sequel = false
  end

  class << self
    def extended(model_class)
      return if model_class.respond_to? :mobility_accessor
      model_class.class_eval do
        def self.mobility
          @mobility ||= Mobility::Wrapper.new(self)
        end
        def self.translated_attribute_names
          mobility.translated_attribute_names
        end

        class << self
          include Translates
          if translates = Mobility.config.accessor_method
            alias_method translates, :mobility_accessor
          end
        end
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

    # Extends model with this class so that +include Mobility+ is equivalent to
    # +extend Mobility+
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
    #   +I18n.available_locales+ (if +I18n.enforce_available_locales+ is +true+)
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
      @configuration ||= Mobility::Configuration.new
    end

    # (see Mobility::Configuration#accessor_method)
    # @!method accessor_method

    # (see Mobility::Configuration#default_fallbacks)
    # @!method default_fallbacks

    # (see Mobility::Configuration#default_backend)
    # @!method default_backend

    # (see Mobility::Configuration#default_accessor_locales)
    # @!method default_accessor_locales
    %w[accessor_method default_backend default_accessor_locales].each do |method_name|
      define_method method_name do
        config.public_send(method_name)
      end
    end

    define_method :default_fallbacks do |*args|
      config.public_send(:default_fallbacks, *args)
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
      "#{locale.to_s.downcase.sub("-", "_")}".freeze
    end
    alias_method :normalized_locale, :normalize_locale

    # Return normalized locale accessor name
    # @param [String,Symbol] attribute
    # @param [String,Symbol] locale
    # @return [String] Normalized locale accessor name
    # @example
    #   Mobility.normalize_locale_accessor(:foo, :ja)
    #   #=> "foo_ja"
    #   Mobility.normalize_locale_accessor(:bar, "pt-BR")
    #   #=> "bar_pt_br"
    def normalize_locale_accessor(attribute, locale = Mobility.locale)
      "#{attribute}_#{normalize_locale(locale)}".freeze
    end

    protected

    def read_locale
      storage[:mobility_locale]
    end

    def set_locale(locale)
      locale = locale.to_sym if locale
      if I18n.enforce_available_locales
        raise Mobility::InvalidLocale.new(locale) unless (I18n.available_locales.include?(locale) || locale.nil?)
      end
      storage[:mobility_locale] = locale
    end
  end

  class BackendRequired < ArgumentError; end
  class InvalidLocale < I18n::InvalidLocale; end
end
