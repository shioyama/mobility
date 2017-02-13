module Mobility
  module Backend

=begin

Stores translations as hash on Postgres hstore column.

==Backend Options

This backend has no options.

@see Mobility::Backend::ActiveRecord::Hstore
@see Mobility::Backend::Sequel::Hstore
@see https://www.postgresql.org/docs/current/static/hstore.html PostgreSQL Documentation for hstore

=end
    module Hstore
      include OrmDelegator
    end
  end
end
