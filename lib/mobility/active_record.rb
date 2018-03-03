# frozen_string_literal: true
module Mobility
=begin

Module loading ActiveRecord-specific classes for Mobility models.

=end
  module ActiveRecord
    require "mobility/active_record/uniqueness_validator"

    class QueryMethod < Module
      def initialize(query_method)
        module_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{query_method}
            all
          end
        EOM
      end
    end

    def self.included(model_class)
      model_class.extend QueryMethod.new(Mobility.query_method)
      unless model_class.const_defined?(:UniquenessValidator)
        model_class.const_set(:UniquenessValidator,
                              Class.new(::Mobility::ActiveRecord::UniquenessValidator))
      end
      model_class.delegate :translated_attribute_names, to: :class
    end
  end
end
