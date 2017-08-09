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

      setup_query_methods(QueryMethods)
    end
  end
end
