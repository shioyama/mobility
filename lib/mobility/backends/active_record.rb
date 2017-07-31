module Mobility
  module Backends
    module ActiveRecord
      autoload :Column,       'mobility/backends/active_record/column'
      autoload :Hstore,       'mobility/backends/active_record/hstore'
      autoload :Jsonb,        'mobility/backends/active_record/jsonb'
      autoload :KeyValue,     'mobility/backends/active_record/key_value'
      autoload :Serialized,   'mobility/backends/active_record/serialized'
      autoload :QueryMethods, 'mobility/backends/active_record/query_methods'
      autoload :Table,        'mobility/backends/active_record/table'

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
