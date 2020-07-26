# frozen_string_literal: true
require "mobility/arel"

module Mobility
=begin

Module loading ActiveRecord-specific classes for Mobility models.

=end
  module ActiveRecord
    require "mobility/active_record/uniqueness_validator"

    def self.included(model_class)
      model_class.delegate :translated_attribute_names, to: :class
    end
  end
end
