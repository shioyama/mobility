# frozen_string_literal: true
module Mobility
  module Backends
=begin

Defines read and write methods that access the value at a key with value
+locale+ on a +translations+ hash.

=end
    module HashValued
      # @!macro backend_constructor
      # @option options [Symbol] prefix Prefix added to generate column
      #   name from attribute name
      # @option options [Symbol] suffix Suffix added to generate column
      #   name from attribute name
      def initialize(_model, _attribute, options = {})
        super
        @column_affix = "#{options[:prefix]}%s#{options[:suffix]}"
      end

      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, _options = nil)
        translations[locale]
      end

      # @!macro backend_writer
      def write(locale, value, _options = nil)
        translations[locale] = value
      end
      # @!endgroup

      # @!macro backend_iterator
      def each_locale
        translations.each { |l, _| yield l }
      end

      private

      def column_name
        @column_name ||= (@column_affix % attribute)
      end
    end
  end
end
