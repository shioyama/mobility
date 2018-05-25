# frozen-string-literal: true
module Mobility
  module Arel
    class Visitor < ::Arel::Visitors::Visitor
      INNER_JOIN = ::Arel::Nodes::InnerJoin
      OUTER_JOIN = ::Arel::Nodes::OuterJoin

      attr_reader :backend_class

      def initialize(backend_class = nil)
        super()
        @backend_class = backend_class
      end

      private

      def visit(object)
        super
      rescue TypeError
        visit_default(object)
      end

      def visit_collection(_objects)
        raise NotImplementedError
      end
      alias :visit_Array :visit_collection

      def visit_Arel_Nodes_Unary(object)
        visit(object.expr)
      end

      def visit_Arel_Nodes_Binary(object)
        visit_collection([object.left, object.right])
      end

      def visit_Arel_Nodes_Function(object)
        visit_collection(object.expressions)
      end

      def visit_Arel_Nodes_Case(object)
        visit_collection([object.case, object.conditions, object.default])
      end

      def visit_Arel_Nodes_And(object)
        visit_Array(object.children)
      end

      def visit_Arel_Nodes_Node(object)
        visit_default(object)
      end

      def visit_Arel_Attributes_Attribute(object)
        visit_default(object)
      end

      def visit_default(_object)
        nil
      end
    end
  end
end
