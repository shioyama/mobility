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

      # Show useful information about this module.
      # @return [String]
      def inspect
        "#<Translations @names=#{names.join(", ")}>"
      end

      included_hook do |klass|
        names = @names

        klass.class_eval do
          extend ClassMethods
          names.each { |name| mobility_attributes << name.to_s }
          mobility_attributes.uniq!
        rescue FrozenError
          raise FrozenAttributesError, "Attempting to translate these attributes on #{klass}, which has already been subclassed: #{names.join(', ')}."
        end
      end

      module ClassMethods
        # Return true if attribute name is translated on this model.
        # @param [String, Symbol] Attribute name
        # @return [Boolean]
        def mobility_attribute?(name)
          mobility_attributes.include?(name.to_s)
        end

        # Return translated attribute names on this model.
        # @return [Array<String>] Attribute names
        def mobility_attributes
          @mobility_attributes ||= []
        end

        def inherited(klass)
          super
          attrs = mobility_attributes.freeze # ensure attributes are not modified after being inherited
          klass.class_eval { @mobility_attributes = attrs.dup }
        end
      end

      class FrozenAttributesError < Error; end
    end

    register_plugin(:attributes, Attributes)
  end
end
