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
      attributes_class.plugin(name, **options)
    end

    # @param [Symbol] name Plugin name
    # @yield Block to define plugins
    def plugins(*args, &block)
      raise ArgumentError, "Pass a block to Configuration#plugins to define plugins." if args.any?
      attributes_class.plugins(&block)
    end

    # Generate new fallbacks instance
    # @note This method will call the proc defined in the variable set by the
    # +fallbacks_generator=+ setter, passing the first argument to its `call`
    # method. By default the generator returns an instance of
    # +I18n::Locale::Fallbacks+.
    # @param fallbacks [Hash] Fallbacks hash passed to generator
    # @return [I18n::Locale::Fallbacks]
    def new_fallbacks(fallbacks = {})
      @fallbacks_generator.call(fallbacks)
    end

    # Assign proc which, passed a set of fallbacks, returns a default fallbacks
    # instance. By default this is a proc which takes fallbacks and returns an
    # instance of +I18n::Locale::Fallbacks+.
    # @param [Proc] fallbacks generator
    attr_writer :fallbacks_generator

    # Default backend to use (can be symbol or actual backend class)
    # @return [Symbol,Class]
    def default_backend
      attributes_class.defaults[:backend]
    end

    def initialize
      @accessor_method = :translates
      @fallbacks_generator = lambda { |fallbacks| Mobility::Fallbacks.build(fallbacks) }
    end

    def attributes_class
      @attributes_class ||= Class.new(Attributes)
    end
  end
end
