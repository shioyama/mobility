module Mobility
  module Backend
    module ActiveRecord
      autoload :Column,       'mobility/backend/active_record/column'
      autoload :Dirty,        'mobility/backend/active_record/dirty'
      autoload :Hstore,       'mobility/backend/active_record/hstore'
      autoload :Jsonb,        'mobility/backend/active_record/jsonb'
      autoload :KeyValue,     'mobility/backend/active_record/key_value'
      autoload :Serialized,   'mobility/backend/active_record/serialized'
      autoload :QueryMethods, 'mobility/backend/active_record/query_methods'
      autoload :Table,        'mobility/backend/active_record/table'

      def setup_query_methods(query_methods)
        setup do |attributes, options|
          extend(Module.new do
            define_method ::Mobility.query_method do
              super().extending(query_methods.new(attributes, options))
            end
          end)
        end
      end

      def self.included(backend_class)
        backend_class.include(Backend)
        backend_class.extend(self)
      end
    end
  end
end
