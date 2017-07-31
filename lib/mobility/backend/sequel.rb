module Mobility
  module Backend
    module Sequel
      autoload :Column,       'mobility/backend/sequel/column'
      autoload :Hstore,       'mobility/backend/sequel/hstore'
      autoload :Jsonb,        'mobility/backend/sequel/jsonb'
      autoload :KeyValue,     'mobility/backend/sequel/key_value'
      autoload :Serialized,   'mobility/backend/sequel/serialized'
      autoload :Table,        'mobility/backend/sequel/table'
      autoload :QueryMethods, 'mobility/backend/sequel/query_methods'

      def setup_query_methods(query_methods)
        setup do |attributes, options|
          extend(Module.new do
            define_method ::Mobility.query_method do
              super().with_extend(query_methods.new(attributes, options))
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
