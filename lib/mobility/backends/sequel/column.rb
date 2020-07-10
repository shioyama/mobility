# frozen_string_literal: true
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

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, _options = nil)
        column = column(locale)
        model[column] if model.columns.include?(column)
      end

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, _options = nil)
        column = column(locale)
        model[column] = value if model.columns.include?(column)
      end

      # @!macro backend_iterator
      def each_locale
        available_locales.each { |l| yield(l) if present?(l) }
      end

      def self.build_op(attr, locale)
        ::Sequel::SQL::QualifiedIdentifier.new(model_class.table_name,
                                               Column.column_name_for(attr, locale))
      end

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

    register_backend(:sequel_column, Sequel::Column)
  end
end
