module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Column} backend for Sequel models.

@note This backend disables the +locale_accessors+ option, which would
  otherwise interfere with column methods.
=end
    class Sequel::Column
      include Backend
      include Backend::Column

      autoload :QueryMethods, 'mobility/backend/sequel/column/query_methods'

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
      def self.configure!(options)
        options[:locale_accessors] = false
      end
      # @!endgroup

      setup do |attributes, options|
        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension
      end
    end
  end
end
