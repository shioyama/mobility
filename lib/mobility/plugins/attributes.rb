# frozen-string-literal: true
module Mobility
  module Plugins
=begin

Takes arguments, converts them to strings, and stores in an array +@names+,
made available with an +attr_reader+. Also provides some convenience methods
for aggregating attributes.

=end
    module Attributes
      extend Plugin

      # Attribute names for which accessors will be defined
      # @return [Array<String>] Array of names
      attr_reader :names

      initialize_hook do |*names|
        @names = names.map(&:to_s).freeze
      end

      # Yield each attribute name to block
      # @yieldparam [String] Attribute
      def each &block
        names.each(&block)
      end

      # Show useful information about this module.
      # @return [String]
      def inspect
        "#<Attributes @names=#{names.join(", ")}>"
      end

      included_hook do |klass|
        klass.extend ClassMethods
        @names.each { |name| klass.register_mobility_attribute(name) }
      end

      module ClassMethods
        # Return true if attribute name is translated on this model.
        # @param [String, Symbol] Attribute name
        # @return [Boolean]
        def mobility_attribute?(name)
          mobility_attributes.include?(name.to_s)
        end

        # Register a new attribute name. Public, but treat as internal.
        # @param [String, Symbol] Attribute name
        def register_mobility_attribute(name)
          (self.mobility_attributes << name.to_s).uniq!
        end

        def inherited(klass)
          super
          mobility_attributes.each { |name| klass.register_mobility_attribute(name) }
        end

        protected

        # Return translated attribute names on this model.
        # @return [Array<String>] Attribute names
        def mobility_attributes
          @mobility_attributes ||= []
        end
      end
    end

    register_plugin(:attributes, Attributes)
  end
end
