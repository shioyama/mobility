require "mobility/util"

module Mobility
  module Plugins
=begin

Applies presence filter to values fetched from backend and to values set on
backend. Included by default, but can be disabled with +presence: false+ option.

=end
    module Presence
      # Applies presence plugin to attributes.
      # @param [Attributes] attributes
      # @param [Boolean] option
      def self.apply(attributes, option)
        attributes.backend_class.include(self) if option
      end

      # @group Backend Accessors
      # @!macro backend_reader
      # @option options [Boolean] presence
      #   *false* to disable presence filter.
      def read(locale, **options)
        return super if options.delete(:presence) == false
        value = super
        value == false ? value : Util.presence(value)
      end

      # @group Backend Accessors
      # @!macro backend_writer
      # @option options [Boolean] presence
      #   *false* to disable presence filter.
      def write(locale, value, **options)
        return super if options.delete(:presence) == false
        super(locale, value == false ? value : Util.presence(value), options)
      end
    end
  end
end
