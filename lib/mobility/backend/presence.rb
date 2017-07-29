module Mobility
  module Backend
=begin

Applies presence filter to values fetched from backend and to values set on
backend. Included by default, but can be disabled with +presence: false+ option.

=end
    module Presence
      # Applies presence option module to attributes.
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
        value == false ? value : value.presence
      end

      # @group Backend Accessors
      # @!macro backend_writer
      # @option options [Boolean] presence
      #   *false* to disable presence filter.
      def write(locale, value, **options)
        return super if options.delete(:presence) == false
        super(locale, value == false ? value : value.presence, options)
      end
    end
  end
end
