module Mobility
=begin

Module loading Sequel-specific classes for Mobility models.

=end
  module Sequel
    def self.included(model_class)
      model_class.extend DatasetMethod.new(Mobility.query_method)
    end

    class DatasetMethod < Module
      def initialize(query_method)
        module_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{query_method}
            dataset
          end
        EOM
      end
    end
    private_constant :DatasetMethod
  end
end
