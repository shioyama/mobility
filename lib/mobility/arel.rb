# frozen-string-literal: true
require "mobility/arel/nodes"
require "mobility/arel/visitor"

module Mobility
  module Arel
    module MobilityExpressions
      include ::Arel::Expressions

      # @note This is necessary in order to ensure that when a translated
      #   attribute is selected with an alias using +AS+, the resulting
      #   expression can still be counted without blowing up.
      #
      #   Extending +::Arel::Expressions+ is necessary to convince ActiveRecord
      #   that this node should not be stringified, which otherwise would
      #   result in garbage SQL.
      #
      # @see https://github.com/rails/rails/blob/847342c25c61acaea988430dc3ab66a82e3ed486/activerecord/lib/active_record/relation/calculations.rb#L261
      def as(*)
        super
          .extend(::Arel::Expressions)
          .extend(Countable)
      end

      module Countable
        # @note This allows expressions with selected translated attributes to
        #   be counted.
        def count(*args)
          left.count(*args)
        end
      end
    end

    class Attribute < ::Arel::Attributes::Attribute
      include MobilityExpressions

      attr_reader :backend_class
      attr_reader :locale
      attr_reader :attribute_name

      def initialize(relation, column_name, locale, backend_class, attribute_name = nil)
        @backend_class = backend_class
        @locale = locale
        @attribute_name = attribute_name || column_name
        super(relation, column_name)
      end
    end
  end
end
