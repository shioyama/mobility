module Mobility
  module Backend
    module ActiveRecord
      autoload :Columns,      'mobility/backend/active_record/columns'
      autoload :KeyValue,     'mobility/backend/active_record/key_value'
      autoload :Serialized,   'mobility/backend/active_record/serialized'
      autoload :QueryMethods, 'mobility/backend/active_record/query_methods'
    end
  end
end
