module Mobility
  module Backends
    autoload :ActiveRecord, 'mobility/backends/active_record'
    autoload :Column,       'mobility/backends/column'
    autoload :HashValued,   'mobility/backends/hash_valued'
    autoload :Hstore,       'mobility/backends/hstore'
    autoload :Jsonb,        'mobility/backends/jsonb'
    autoload :KeyValue,     'mobility/backends/key_value'
    autoload :Null,         'mobility/backends/null'
    autoload :Sequel,       'mobility/backends/sequel'
    autoload :Serialized,   'mobility/backends/serialized'
    autoload :Table,        'mobility/backends/table'
  end
end
