module Mobility
  module Backends
=begin

Backend which stores translations in an in-memory hash.

=end
    class Hash
      include Backend

      # @!group Backend Accessors
      # @!macro backend_reader
      # @return [Object]
      def read(locale, _ = {})
        translations[locale]
      end

      # @!macro backend_writer
      # @return [Object]
      def write(locale, value, _ = {})
        translations[locale] = value
      end
      # @!endgroup

      # @!macro backend_iterator
      def each_locale
        translations.each { |l, _| yield l }
      end

      private

      def translations
        @translations ||= {}
      end
    end

    register_backend(:hash, Hash)
  end
end
