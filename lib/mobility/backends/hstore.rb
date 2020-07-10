module Mobility
  module Backends

=begin

Stores translations as hash on Postgres hstore column.

==Backend Options

===+column_prefix+ and +column_suffix+

Prefix and suffix to add to attribute name to generate hstore column name.

@see Mobility::Backends::ActiveRecord::Hstore
@see Mobility::Backends::Sequel::Hstore
@see https://www.postgresql.org/docs/current/static/hstore.html PostgreSQL Documentation for hstore

=end
    module Hstore
    end

    register_backend(:hstore, Hstore)
  end
end
