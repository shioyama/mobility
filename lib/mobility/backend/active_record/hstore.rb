require 'mobility/backend/active_record/hash_backend'

module Mobility
  module Backend
    class ActiveRecord::Hstore < ActiveRecord::HashBackend
      autoload :QueryMethods, 'mobility/backend/active_record/hstore/query_methods'

      setup do |attributes, options|
        query_methods = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend query_methods
      end
    end
  end
end
