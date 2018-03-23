# frozen_string_literal: true

module Mobility
=begin

Some useful methods on strings, borrowed in parts from Sequel and ActiveSupport.

@example With no methods defined on String
  "foos".respond_to?(:singularize)
  #=> false

  class A
    include Mobility::Util
  end

  A.new.singularize("foos")
  #=> "foo"
  A.new.singularize("bunnies")
  #=> "bunnie"

@example With methods on String
  require "active_support"
  "foos".respond_to?(:singularize)
  #=> true

  class A
    include Mobility::Util
  end

  A.new.singularize("bunnies")
  #=> "bunny"
=end
  module Util
    VALID_CONSTANT_NAME_REGEXP = /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/.freeze

    def self.included(klass)
      klass.extend(self)
    end

    # Converts strings to UpperCamelCase.
    # @param [String] str
    # @return [String]
    def camelize(str)
      call_or_yield str do
        str.to_s.sub(/^[a-z\d]*/) { $&.capitalize }.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
      end
    end

    # Tries to find a constant with the name specified in the argument string.
    # @param [String] str
    # @return [Object]
    def constantize(str)
      str = str.to_s
      call_or_yield str do
        raise(NameError, "#{s.inspect} is not a valid constant name!") unless m = VALID_CONSTANT_NAME_REGEXP.match(str)
        Object.module_eval("::#{m[1]}", __FILE__, __LINE__)
      end
    end

    # Returns the singular form of a word in a string.
    # @param [String] str
    # @return [String]
    # @note If +singularize+ is not defined on +String+, falls back to simply
    #   stripping the trailing 's' from the string.
    def singularize(str)
      call_or_yield str do
        str.to_s.gsub(/s$/, '')
      end
    end

    # Removes the module part from the expression in the string.
    # @param [String] str
    # @return [String]
    def demodulize(str)
      call_or_yield str do
        str.to_s.gsub(/^.*::/, '')
      end
    end

    # Creates a foreign key name from a class name
    # @param [String] str
    # @return [String]
    def foreign_key(str)
      call_or_yield str do
        "#{underscore(demodulize(str))}_id"
      end
    end

    # Makes an underscored, lowercase form from the expression in the string.
    # @param [String] str
    # @return [String]
    def underscore(str)
      call_or_yield str do
        str.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
      end
    end

    def present?(object)
      !blank?(object)
    end

    def blank?(object)
      object.nil? || object == ""
    end

    def presence(object)
      object if present?(object)
    end

    private

    # Calls caller method on object if defined, otherwise yields to block
    def call_or_yield(object)
      caller_method = caller_locations(1,1)[0].label
      if object.respond_to?(caller_method)
        object.public_send(caller_method)
      else
        yield
      end
    end

    extend self
  end
end
