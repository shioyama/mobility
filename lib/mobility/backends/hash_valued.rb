module Mobility
  module Backends
=begin

Defines read and write methods that access the value at a key with value
+locale+ on a +translations+ hash.

=end
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

      # @!macro backend_iterator
      def each
        translations.each { |l, _| yield l }
      end
    end
  end
end
