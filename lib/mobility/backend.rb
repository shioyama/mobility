module Mobility
  module Backend
    autoload :Base,      'mobility/backend/base'
    autoload :Cache,     'mobility/backend/cache'
    autoload :Columns,   'mobility/backend/columns'
    autoload :Dirty,     'mobility/backend/dirty'
    autoload :Fallbacks, 'mobility/backend/fallbacks'
    autoload :Null,      'mobility/backend/null'
    autoload :Table,     'mobility/backend/table'

    def self.method_name(attribute)
      "#{attribute}_translations"
    end
  end
end
