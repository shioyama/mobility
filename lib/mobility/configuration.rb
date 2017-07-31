module Mobility
=begin

Stores shared Mobility configuration referenced by all backends.

=end
  class Configuration
    RESERVED_OPTION_KEYS = %i[backend model_class].freeze

    # Alias for mobility_accessor (defaults to +translates+)
    # @return [Symbol]
    attr_accessor :accessor_method

    # Name of query scope/dataset method (defaults to +i18n+)
    # @return [Symbol]
    attr_accessor :query_method

    # Default set of options. These will be merged with any backend options
    # when defining translated attributes (with +translates+). Default options
    # may not include the keys 'backend' or 'model_class'.
    # @return [Hash]
    attr_reader :default_options
    def default_options=(options)
      if (keys = options.keys & RESERVED_OPTION_KEYS).present?
        raise ReservedOptionKey,
          "Default options may not contain the following reserved keys: #{keys.join(', ')}"
      else
        @default_options = options
      end
    end

    # Option modules to apply. Defines which module to apply for each option
    # key. Order of hash keys/values is important, as this becomes the order in
    # which modules are applied and included into the backend class or
    # attributes instance.
    # @return [Hash]
    attr_accessor :plugins

    # Default fallbacks instance
    # @return [I18n::Locale::Fallbacks]
    def default_fallbacks(fallbacks = {})
      @default_fallbacks.call(fallbacks)
    end
    attr_writer :default_fallbacks

    # Default backend to use (can be symbol or actual backend class)
    # @return [Symbol,Class]
    attr_accessor :default_backend

    # Returns set of default accessor locles to use (defaults to
    # +I18n.available_locales+)
    # @return [Array<Symbol>]
    def default_accessor_locales
      if @default_accessor_locales.is_a?(Proc)
        @default_accessor_locales.call
      else
        @default_accessor_locales
      end
    end
    attr_writer :default_accessor_locales

    def initialize
      @accessor_method = :translates
      @query_method = :i18n
      @default_fallbacks = lambda { |fallbacks| I18n::Locale::Fallbacks.new(fallbacks) }
      @default_accessor_locales = lambda { I18n.available_locales }
      @default_options = {
        cache: true,
        dirty: false,
        fallbacks: nil,
        presence: true,
        default: nil
      }
      @plugins = {
        cache:                 Plugins::Cache,
        dirty:                 Plugins::Dirty,
        fallbacks:             Plugins::Fallbacks,
        presence:              Plugins::Presence,
        default:               Plugins::Default,
        fallthrough_accessors: Plugins::FallthroughAccessors,
        locale_accessors:      Plugins::LocaleAccessors
      }
    end

    class ReservedOptionKey < Exception; end
  end
end
