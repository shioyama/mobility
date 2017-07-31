module Mobility
  module Backends

=begin

Stores translations as hash on Postgres jsonb column.

==Backend Options

This backend has no options.

@see Mobility::Backends::ActiveRecord::Jsonb
@see Mobility::Backends::Sequel::Jsonb
@see https://www.postgresql.org/docs/current/static/datatype-json.html PostgreSQL Documentation for JSON Types

=end
    module Jsonb
      extend Backend::OrmDelegator
    end
  end
end
