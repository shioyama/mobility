module Mobility
=begin

Module loading Sequel-specific classes for Mobility models.

=end
  module Sequel
    def self.included(model_class)
      query_method = Module.new do
        define_method Mobility.query_method do
          dataset
        end
      end
      model_class.extend query_method
    end
  end
end
