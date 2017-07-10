module Mobility
=begin

Stores shared Mobility configuration referenced by all backends.

=end
  class Configuration
    # Alias for mobility_accessor (defaults to +translates+)
    # @return [Symbol]
    attr_accessor :accessor_method

    # Name of query scope/dataset method (defaults to +i18n+)
    # @return [Symbol]
    attr_accessor :query_method

    # Default set of options
    # @return [Hash]
    attr_accessor :default_options

    # Option modules to apply
    # @return [Hash]
    attr_accessor :option_modules

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
      @option_modules = {
        cache:                 Backend::Cache,
        dirty:                 Backend::Dirty,
        fallbacks:             Backend::Fallbacks,
        presence:              Backend::Presence,
        default:               Backend::Default,
        fallthrough_accessors: FallthroughAccessors,
        locale_accessors:      LocaleAccessors
      }
    end
  end
end
