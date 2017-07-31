module Mobility
  module Backends

=begin

Stores translations as hash on Postgres hstore column.

==Backend Options

This backend has no options.

@see Mobility::Backends::ActiveRecord::Hstore
@see Mobility::Backends::Sequel::Hstore
@see https://www.postgresql.org/docs/current/static/hstore.html PostgreSQL Documentation for hstore

=end
    module Hstore
      extend Backend::OrmDelegator
    end
  end
end
