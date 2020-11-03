module Mobility
  module Backends

=begin

Stores translations for multiple attributes on a single shared Postgres jsonb
column (called a "container").

==Backend Options

===+column_name+

Name of the column for the translations container (where translations are
stored).

@see Mobility::Backends::ActiveRecord::Container
@see Mobility::Backends::Sequel::Container
@see https://www.postgresql.org/docs/current/static/datatype-json.html PostgreSQL Documentation for JSON Types

=end
    module Container
      def self.included(backend_class)
        backend_class.extend ClassMethods
        backend_class.option_reader :column_name
      end

      module ClassMethods
        def valid_keys
          [:column_name]
        end
      end
    end
  end
end
