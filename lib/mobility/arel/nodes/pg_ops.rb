# frozen-string-literal: true
require "mobility/arel"

module Mobility
  module Arel
    module Nodes
      %w[
        JsonDashArrow
        JsonDashDoubleArrow
        JsonbDashArrow
        JsonbDashDoubleArrow
        JsonbQuestion
        HstoreDashArrow
        HstoreQuestion
      ].each do |name|
        const_set name, (Class.new(Binary) do
          include ::Arel::Expressions
          include ::Arel::Predications
          include ::Arel::OrderPredications
          include ::Arel::AliasPredication

          def eq(other)
            Equality.new self, quoted_node(other)
          end
        end)
      end

      JsonbDashArrow.class_eval do
        def quoted_node(other)
          other && super(other.to_json)
        end
      end

      # Needed for AR 4.2, can be removed when support is deprecated
      HstoreDashArrow.class_eval do
        def quoted_node(other)
          other && super
        end
      end

      class Jsonb  < JsonbDashArrow
        def lower
          left.relation.lower JsonbDashDoubleArrow.new(left, right)
        end
      end

      class Hstore < HstoreDashArrow
        def lower
          left.relation.lower self
        end
      end

      class Json   < JsonDashDoubleArrow
        def lower
          left.relation.lower self
        end
      end

      class JsonContainer < Json
        def initialize(column, locale, attr)
          @column = column
          super(Arel::Nodes::JsonDashArrow.new(column, locale), attr)
        end

        def lower
          @column.relation.lower JsonDashDoubleArrow.new(left, right)
        end
      end

      class JsonbContainer < Jsonb
        def initialize(column, locale, attr)
          @column = column
          super(Jsonb.new(column, locale), attr)
        end

        def lower
          @column.relation.lower JsonbDashDoubleArrow.new(left, right)
        end
      end
    end

    module Visitors
      def visit_Mobility_Arel_Nodes_Equality o, a
        left, right = o.left, o.right

        if right.nil?
          case left
          when Nodes::Jsonb
            nodes = []
            while Nodes::Jsonb === left
              left, right = left.left, left.right
              nodes << Nodes::JsonbQuestion.new(left, right).not
            end
            return visit(nodes.inject(&:or), a)
          when Nodes::Hstore
            return visit(Nodes::HstoreQuestion.new(left.left, left.right).not, a)
          end
        end

        super o, a
      end

      def visit_Mobility_Arel_Nodes_JsonDashArrow o, a
        json_infix o, a, '->'
      end

      def visit_Mobility_Arel_Nodes_JsonDashDoubleArrow o, a
        json_infix o, a, '->>'
      end

      def visit_Mobility_Arel_Nodes_JsonbDashArrow o, a
        json_infix o, a, '->'
      end

      def visit_Mobility_Arel_Nodes_JsonbDashDoubleArrow o, a
        json_infix o, a, '->>'
      end

      def visit_Mobility_Arel_Nodes_JsonbQuestion o, a
        json_infix o, a, '?'
      end

      def visit_Mobility_Arel_Nodes_HstoreDashArrow o, a
        json_infix o, a, '->'
      end

      def visit_Mobility_Arel_Nodes_HstoreQuestion o, a
        json_infix o, a, '?'
      end

      private

      def json_infix(o, a, opr)
        visit(Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new(opr, o.left, o.right)), a)
      end
    end

    ::Arel::Visitors::PostgreSQL.include Visitors
  end
end
