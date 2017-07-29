require 'mobility/backend/sequel/hash_valued'

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Hstore} backend for Sequel models.

@see Mobility::Backend::Sequel::HashValued

=end
    class Sequel::Hstore < Sequel::HashValued
      require 'mobility/backend/sequel/hstore/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, _ = {})
        translations[locale.to_s] = value && value.to_s
      end
      # @!endgroup

      setup_query_methods(QueryMethods)
    end
  end
end
