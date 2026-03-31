# frozen-string-literal: true
require "mobility/plugins/arel"

module Mobility
  module Plugins
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
            include ::Arel::Predications
            include ::Arel::OrderPredications
            include ::Arel::AliasPredication
            include MobilityExpressions

            def lower
              super self
            end
          end)
        end

        class Jsonb  < JsonbDashDoubleArrow
          def to_dash_arrow
            JsonbDashArrow.new left, right
          end

          def to_question
            JsonbQuestion.new left, right
          end

          def eq other
            case other
            when NilClass
              to_question.not
            when Integer, Array, ::Hash
              to_dash_arrow.eq other.to_json
            when Jsonb
              to_dash_arrow.eq other.to_dash_arrow
            when JsonbDashArrow
              to_dash_arrow.eq other
            else
              super
            end
          end
        end

        class Hstore < HstoreDashArrow
          def to_question
            HstoreQuestion.new left, right
          end

          def eq other
            other.nil? ? to_question.not : super
          end
        end

        class Json < JsonDashDoubleArrow; end

        class JsonContainer < Json
          def initialize column, locale, attr
            super(Nodes::JsonDashArrow.new(column, locale), attr)
          end
        end

        class JsonbContainer < Jsonb
          def initialize column, locale, attr
            @column, @locale = column, locale
            super(JsonbDashArrow.new(column, locale), attr)
          end

          def eq other
            other.nil? ? super.or(JsonbQuestion.new(@column, @locale).not) : super
          end
        end
      end

      module Visitors
        def visit_Mobility_Plugins_Arel_Nodes_JsonDashArrow o, a
          json_infix o, a, '->'
        end

        def visit_Mobility_Plugins_Arel_Nodes_JsonDashDoubleArrow o, a
          quote_mysql_json_key!(o) if mysql_visitor?
          json_infix o, a, '->>'
        end

        def visit_Mobility_Plugins_Arel_Nodes_JsonbDashArrow o, a
          json_infix o, a, '->'
        end

        def visit_Mobility_Plugins_Arel_Nodes_JsonbDashDoubleArrow o, a
          json_infix o, a, '->>'
        end

        def visit_Mobility_Plugins_Arel_Nodes_JsonbQuestion o, a
          json_infix o, a, '?'
        end

        def visit_Mobility_Plugins_Arel_Nodes_HstoreDashArrow o, a
          json_infix o, a, '->'
        end

        def visit_Mobility_Plugins_Arel_Nodes_HstoreQuestion o, a
          json_infix o, a, '?'
        end

        private

        def mysql_visitor?
          (defined?(::Arel::Visitors::MySQL) && is_a?(::Arel::Visitors::MySQL)) ||
            (defined?(::Arel::Visitors::MySQL2) && is_a?(::Arel::Visitors::MySQL2))
        end

        # MySQL requires JSON path to be prefixed with '$.' and keys quoted to
        # support locales like "pt-BR" when using the ->> operator.
        def quote_mysql_json_key!(node)
          return unless node.respond_to?(:right) && node.right.respond_to?(:value)

          value = node.right.value.to_s
          return if value.start_with?('$.')

          node.right = node.right.class.new(%Q($."#{value}"))
        end

        def json_infix o, a, opr
          node = Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new(opr, o.left, o.right))

          if mysql_visitor? && opr == '->>'
            node = Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new('COLLATE', node, ::Arel::Nodes::SqlLiteral.new('utf8mb4_general_ci')))
          end

          visit(node, a)
        end
      end

      ::Arel::Visitors::PostgreSQL.include Visitors
      ::Arel::Visitors::MySQL.include Visitors if defined?(::Arel::Visitors::MySQL)
      ::Arel::Visitors::MySQL2.include Visitors if defined?(::Arel::Visitors::MySQL2)
    end
  end
end
