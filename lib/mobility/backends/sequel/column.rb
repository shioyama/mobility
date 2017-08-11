require "mobility/backends/sequel"
require "mobility/backends/column"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Column} backend for Sequel models.

=end
    class Sequel::Column
      include Sequel
      include Column

      require 'mobility/backends/sequel/column/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, _ = {})
        column = column(locale)
        model[column] if model.columns.include?(column)
      end

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, _ = {})
        column = column(locale)
        model[column] = value if model.columns.include?(column)
      end

      # @!macro backend_iterator
      def each
        available_locales.each { |l| yield(l) if present?(l) }
      end

      setup_query_methods(QueryMethods)

      private

      def available_locales
        @available_locales ||= get_column_locales
      end

      def get_column_locales
        column_name_regex = /\A#{attribute}_([a-z]{2}(_[a-z]{2})?)\z/.freeze
        model.columns.map do |c|
          (match = c.to_s.match(column_name_regex)) && match[1].to_sym
        end.compact
      end
    end
  end
end
