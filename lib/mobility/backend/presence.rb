module Mobility
  module Backend
=begin

Applies presence filter to values fetched from backend and to values set on
backend. Included by default, but can be disabled with presence: false option.

=end
    module Presence
      # @param [Class] backend_class
      # @param [Boolean] value
      # @param [Hash] _options
      def self.apply(backend_class, value, **_options)
        backend_class.include(self) unless value == false
      end

      # @group Backend Accessors
      # @!macro backend_reader
      # @param [Boolean] presence
      #   *false* to disable presence filter.
      def read(locale, **options)
        return super if options.delete(:presence) == false
        value = super
        value == false ? value : value.presence
      end

      # @group Backend Accessors
      # @!macro backend_writer
      # @param [Boolean] presence
      #   *false* to disable presence filter.
      def write(locale, value, **options)
        return super if options.delete(:presence) == false
        super(locale, value == false ? value : value.presence, **options)
      end
    end
  end
end
