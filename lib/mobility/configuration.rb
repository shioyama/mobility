# frozen_string_literal: true

module Mobility
=begin

Stores shared Mobility configuration referenced by all backends.

=end
  class Configuration
    # Alias for mobility_accessor (defaults to +translates+)
    # @return [Symbol]
    attr_accessor :accessor_method

    # @param [Symbol] name Plugin name
    def plugin(name, **options)
      translations_class.plugin(name, **options)
    end

    # @param [Symbol] name Plugin name
    # @yield Block to define plugins
    def plugins(*args, &block)
      raise ArgumentError, "Pass a block to Configuration#plugins to define plugins." if args.any?
      translations_class.plugins(&block)
    end

    # Default backend to use (can be symbol or actual backend class)
    # @return [Symbol,Class]
    def default_backend
      translations_class.defaults[:backend]
    end

    def initialize
      @accessor_method = :translates
    end

    def translations_class
      @translations_class ||= Class.new(Attributes)
    end
  end
end
