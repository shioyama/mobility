module Mobility
  module Backend

=begin

Stores translations as hash on Postgres jsonb column.

==Backend Options

This backend has no options.

@see Mobility::Backend::ActiveRecord::Jsonb
@see Mobility::Backend::Sequel::Jsonb
@see https://www.postgresql.org/docs/current/static/datatype-json.html PostgreSQL Documentation for JSON Types

=end
    module Jsonb
      include OrmDelegator
    end
  end
end
