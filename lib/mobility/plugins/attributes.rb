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

      initialize_hook do |*names, **|
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

      included_hook do |klass, *, **|
        klass.extend ClassMethods
      end

      module ClassMethods
        # Return all {Mobility::Attributes} module instances from among ancestors
        # of this model.
        # @return [Array<Mobility::Attributes>] Attribute modules
        def mobility_modules
          ancestors.grep(Attributes)
        end

        # Return translated attribute names on this model.
        # @return [Array<String>] Attribute names
        def mobility_attributes
          mobility_modules.map(&:names).flatten.uniq
        end

        # Return true if attribute name is translated on this model.
        # @param [String, Symbol] Attribute name
        # @return [Boolean]
        def mobility_attribute?(name)
          mobility_attributes.include?(name.to_s)
        end
      end
    end

    register_plugin(:attributes, Attributes)
  end
end
