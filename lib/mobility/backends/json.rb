module Mobility
  module Backends
=begin

Stores translations as hash on Postgres json column.

==Backend Options

This backend has no options.

@see Mobility::Backends::ActiveRecord::Json
@see Mobility::Backends::Sequel::Json
@see https://www.postgresql.org/docs/current/static/datatype-json.html PostgreSQL Documentation for JSON Types

=end
    module Json
      extend Backend::OrmDelegator
    end
  end
end
