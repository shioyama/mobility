module Mobility
=begin

Stores shared Mobility configuration referenced by all backends.

=end
  class Configuration
    # Alias for mobility_accessor (defaults to +translates+)
    # @return [Symbol]
    attr_accessor :accessor_method

    # Default fallbacks instance
    # @return [I18n::Locale::Fallbacks]
    attr_accessor :default_fallbacks

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
      @default_fallbacks = I18n::Locale::Fallbacks.new
      @default_accessor_locales = lambda { I18n.available_locales }
    end
  end
end
