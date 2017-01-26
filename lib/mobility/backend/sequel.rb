module Mobility
  module Backend
    module Sequel
      autoload :Column,       'mobility/backend/sequel/column'
      autoload :Dirty,        'mobility/backend/sequel/dirty'
      autoload :Jsonb,        'mobility/backend/sequel/jsonb'
      autoload :KeyValue,     'mobility/backend/sequel/key_value'
      autoload :Serialized,   'mobility/backend/sequel/serialized'
      autoload :QueryMethods, 'mobility/backend/sequel/query_methods'
    end
  end
end
