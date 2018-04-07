module Mobility
  module Backends

=begin

Stores translations as hash on Postgres hstore column.

==Backend Options

===+prefix+ and +suffix+

Prefix and suffix to add to attribute name to generate hstore column name.

@see Mobility::Backends::ActiveRecord::Hstore
@see Mobility::Backends::Sequel::Hstore
@see https://www.postgresql.org/docs/current/static/hstore.html PostgreSQL Documentation for hstore

=end
    module Hstore
      extend Backend::OrmDelegator
    end
  end
end
