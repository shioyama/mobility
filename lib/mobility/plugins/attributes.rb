# frozen-string-literal: true
module Mobility
  module Plugins
=begin

Takes arguments, converts them to strings, and stores in an array +@names+,
made available with an +attr_reader+.

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
    end

    register_plugin(:attributes, Attributes)
  end
end
