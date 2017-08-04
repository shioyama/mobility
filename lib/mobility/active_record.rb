module Mobility
=begin

Module loading ActiveRecord-specific classes for Mobility models.

=end
  module ActiveRecord
    require "mobility/active_record/attribute_methods"
    require "mobility/active_record/uniqueness_validator"

    def self.included(model_class)
      query_method = Module.new do
        define_method Mobility.query_method do
          all
        end
      end
      model_class.extend query_method
      model_class.const_set(:UniquenessValidator,
                            Class.new(::Mobility::ActiveRecord::UniquenessValidator))
    end
  end
end
