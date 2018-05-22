# frozen_string_literal: true
require "mobility/util"

module Mobility
  module Backends
    module Sequel
=begin

Defines query method overrides to handle translated attributes for Sequel
models. For details see backend-specific subclasses.

=end
      class QueryMethods < Module
        # @param [Array<String>] attributes Translated attributes
        def initialize(attributes, _)
          @attributes = attributes.map(&:to_sym)

          @attributes.each do |attribute|
            define_method :"first_by_#{attribute}" do |value|
              where(attribute => value).select_all(model.table_name).first
            end
          end
        end

        def extract_attributes(cond)
          cond.is_a?(Hash) && Util.presence(cond.keys & @attributes)
        end

        def collapse(value)
          value.is_a?(Array) ? value.uniq : value
        end
      end
      private_constant :QueryMethods
    end
  end
end
