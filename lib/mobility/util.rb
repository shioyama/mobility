require "singleton"

module Mobility
  module Util
    VALID_CONSTANT_NAME_REGEXP = /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/.freeze

    def self.included(klass)
      klass.extend(self)
    end

    # Converts strings to UpperCamelCase.
    # @param [String] str
    # @return [String]
    def camelize(str)
      str.to_s.sub(/^[a-z\d]*/) { $&.capitalize }.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/'.freeze, '::'.freeze)
    end

    # Tries to find a constant with the name specified in the argument string.
    # @param [String] str
    # @return [Object]
    def constantize(str)
      str = str.to_s
      raise(NameError, "#{s.inspect} is not a valid constant name!") unless m = VALID_CONSTANT_NAME_REGEXP.match(str)
      Object.module_eval("::#{m[1]}", __FILE__, __LINE__)
    end

    # Returns the singular form of a word in a string.
    # @param [String] str
    # @return [String]
    # @note Simply strips the trailing 's' from a string.
    def singularize(str)
      str.to_s.gsub(/s$/, '')
    end

    # Removes the module part from the expression in the string.
    # @param [String] str
    # @return [String]
    def demodulize(str)
      str.to_s.gsub(/^.*::/, '')
    end

    # Creates a foreign key name from a class name
    # @param [String] str
    # @return [String]
    def foreign_key(str)
      "#{underscore(demodulize(str))}_id"
    end

    # Makes an underscored, lowercase form from the expression in the string.
    # @param [String] str
    # @return [String]
    def underscore(str)
      str.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
    end

    extend self
  end
end
