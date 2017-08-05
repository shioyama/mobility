module Mobility
  module Backends
    module Sequel
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
