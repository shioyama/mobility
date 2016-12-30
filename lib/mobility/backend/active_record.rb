module Mobility
  module Backend
    module ActiveRecord
      autoload :Columns,      'mobility/backend/active_record/columns'
      autoload :Table,        'mobility/backend/active_record/table'
      autoload :QueryMethods, 'mobility/backend/active_record/query_methods'
    end
  end
end
