# frozen-string-literal: true
require "mobility/arel/nodes"
require "mobility/arel/visitor"

module Mobility
  module Arel
    class Attribute < ::Arel::Attributes::Attribute
      attr_reader :backend_class
      attr_reader :locale
      attr_reader :attribute_name

      def initialize(relation, column_name, locale, backend_class, attribute_name: nil)
        @backend_class = backend_class
        @locale = locale
        @attribute_name = attribute_name || column_name
        super(relation, column_name)
      end
    end
  end
end
