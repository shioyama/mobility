# frozen_string_literal: true
module Mobility
=begin

Module loading ActiveRecord-specific classes for Mobility models.

=end
  module ActiveRecord
    require "mobility/active_record/uniqueness_validator"

    def self.included(model_class)
      model_class.class_eval do
        extend QueryMethod.new(Mobility.query_method)
        unless const_defined?(:UniquenessValidator)
          const_set(:UniquenessValidator,
                    Class.new(::Mobility::ActiveRecord::UniquenessValidator))
        end
        delegate :translated_attribute_names, to: :class
      end
    end

    class QueryMethod < Module
      def initialize(query_method)
        module_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{query_method}
            all
          end
        EOM
      end
    end
    private_constant :QueryMethod
  end
end
