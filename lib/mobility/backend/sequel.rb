module Mobility
  module Backend
    module Sequel
      autoload :Columns,      'mobility/backend/sequel/columns'
      autoload :Dirty,        'mobility/backend/sequel/dirty'
      autoload :KeyValue,     'mobility/backend/sequel/key_value'
      autoload :Serialized,   'mobility/backend/sequel/serialized'
      autoload :QueryMethods, 'mobility/backend/sequel/query_methods'
    end
  end
end
