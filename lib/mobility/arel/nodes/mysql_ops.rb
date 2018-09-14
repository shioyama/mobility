# frozen-string-literal: true
require "mobility/arel"

module Mobility
  module Arel
    module Nodes
      %w[
        JsonDashArrow
        JsonDashDoubleArrow
      ].each do |name|
        const_set name, (Class.new(Binary) do
          include ::Arel::Expressions
          include ::Arel::Predications
          include ::Arel::OrderPredications
          include ::Arel::AliasPredication

          def lower
            super self
          end
        end)
      end

      class Json < JsonDashDoubleArrow; end

      class JsonContainer < Json
        def initialize column, locale, attr
          super(Arel::Nodes::JsonDashArrow.new(column, locale), attr)
        end
      end
    end

    module Visitors
      def visit_Mobility_Arel_Nodes_JsonDashArrow o, a
        json_infix o, a, '->'
      end

      def visit_Mobility_Arel_Nodes_JsonDashDoubleArrow o, a
        json_infix o, a, '->>'
      end

      private

      def json_infix o, a, opr
        visit(Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new(opr, o.left, o.right)), a)
      end
    end

    ::Arel::Visitors::MySQL.include Visitors
  end
end
