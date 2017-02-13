require 'mobility/backend/active_record/hash_valued'

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Hstore} backend for ActiveRecord models.

@see Mobility::Backend::ActiveRecord::HashValued

=end
    class ActiveRecord::Hstore < ActiveRecord::HashValued
      autoload :QueryMethods, 'mobility/backend/active_record/hstore/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, **options)
        translations[locale] = value && value.to_s
      end
      # @!endgroup

      setup do |attributes, options|
        query_methods = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend query_methods
      end
    end
  end
end
