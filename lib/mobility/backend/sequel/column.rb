module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Column} backend for Sequel models.

@note This backend disables the +locale_accessors+ option, which would
  otherwise interfere with column methods.
=end
    class Sequel::Column
      include Sequel
      include Column

      require 'mobility/backend/sequel/column/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, **_)
        column = column(locale)
        model.send(column) if model.columns.include?(column)
      end

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, **_)
        column = column(locale)
        model.send("#{column}=", value) if model.columns.include?(column)
      end

      # @!group Backend Configuration
      def self.configure(options)
        options[:locale_accessors] = false
      end
      # @!endgroup

      setup_query_methods(QueryMethods)
    end
  end
end
