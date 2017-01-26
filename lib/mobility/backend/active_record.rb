module Mobility
  module Backend
    module ActiveRecord
      autoload :Column,       'mobility/backend/active_record/column'
      autoload :Jsonb,        'mobility/backend/active_record/jsonb'
      autoload :KeyValue,     'mobility/backend/active_record/key_value'
      autoload :Serialized,   'mobility/backend/active_record/serialized'
      autoload :QueryMethods, 'mobility/backend/active_record/query_methods'
    end
  end
end
