module Mobility
  module Backend
    module HashValued
      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, _ = {})
        translations[locale]
      end

      # @!macro backend_writer
      def write(locale, value, _ = {})
        translations[locale] = value
      end
      # @!endgroup
    end
  end
end
