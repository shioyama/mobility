# frozen_string_literal: true
module Mobility
  module Backends
=begin

Defines read and write methods that access the value at a key with value
+locale+ on a +translations+ hash.

=end
    module HashValued
      # @return [String] Affix to generate column names
      # @!method column_affix

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

      def self.included(backend_class)
        backend_class.extend ClassMethods
        backend_class.option_reader :column_affix
      end

      module ClassMethods
        def configure(options)
          options[:column_affix] = "#{options[:column_prefix]}%s#{options[:column_suffix]}"
        end
      end

      private

      def column_name
        @column_name ||= (column_affix % attribute)
      end
    end

    private_constant :HashValued
  end
end
