# frozen-string-literal: true

module Mobility
  module Plugins
=begin

Plugin for Mobility Arel customizations. Basically used as a namespace to store
Arel-specific classes and modules.

=end
    module Arel
      extend Plugin

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

      class Visitor < ::Arel::Visitors::Visitor
        INNER_JOIN = ::Arel::Nodes::InnerJoin
        OUTER_JOIN = ::Arel::Nodes::OuterJoin

        attr_reader :backend_class, :locale

        def initialize(backend_class, locale)
          super()
          @backend_class, @locale = backend_class, locale
        end

        private

        def visit(*args)
          super
        rescue TypeError
          visit_default(*args)
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

      module Nodes
        class Binary < ::Arel::Nodes::Binary; end
        class Grouping < ::Arel::Nodes::Grouping; end

        ::Arel::Visitors::ToSql.class_eval do
          alias :visit_Mobility_Plugins_Arel_Nodes_Grouping :visit_Arel_Nodes_Grouping
        end
      end
    end

    register_plugin(:arel, Arel)
  end
end
