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
    end

    register_backend(:container, Container)
  end
end
