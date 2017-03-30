module Mobility
  module Backend
=begin

Applies presence filter to values fetched from backend and to values set on
backend. Included by default, but can be disabled with presence: false option.

=end
    module Presence
      # @group Backend Accessors
      # @!macro backend_reader
      def read(locale, **_)
        value = super
        value == false ? value : value.presence
      end

      # @group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, **options)
        super(locale, value == false ? value : value.presence, **options)
      end
    end
  end
end
