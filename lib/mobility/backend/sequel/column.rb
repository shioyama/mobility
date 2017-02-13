module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Column} backend for Sequel models.

@note This backend disables the +accessor_locales+ option, which would
  otherwise interfere with column methods.
=end
    class Sequel::Column
      include Backend
      include Mobility::Backend::Column

      autoload :QueryMethods, 'mobility/backend/sequel/column/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @!macro backend_writer
      # @!method write(locale, value, **options)

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
