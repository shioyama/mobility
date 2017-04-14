require 'mobility/backend/active_record/hash_valued'

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Hstore} backend for ActiveRecord models.

@see Mobility::Backend::ActiveRecord::HashValued

=end
    class ActiveRecord::Hstore < ActiveRecord::HashValued
      require 'mobility/backend/active_record/hstore/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, **_)
        translations[locale] = value && value.to_s
      end
      # @!endgroup

      setup_query_methods(QueryMethods)
    end
  end
end
