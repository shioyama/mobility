# frozen-string-literal: true
require "mobility/plugins/arel"

module Mobility
  module Plugins
    module Arel
      module Nodes
        %w[
          JsonDashArrow
          JsonDashDoubleArrow
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

        class Json < JsonDashDoubleArrow; end

        class JsonContainer < Json
          def initialize column, locale, attr
            super(Nodes::JsonDashArrow.new(column, locale), attr)
          end
        end
      end

      module Visitors
        module PostgreSQL
          def visit_Mobility_Plugins_Arel_Nodes_JsonDashArrow o, a
            json_infix o, a, '->'
          end

          def visit_Mobility_Plugins_Arel_Nodes_JsonDashDoubleArrow o, a
            json_infix o, a, '->>'
          end

          private

          def json_infix o, a, opr
            visit(Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new(opr, o.left, o.right)), a)
          end
        end

        module MySQL
          def visit_Mobility_Plugins_Arel_Nodes_JsonDashArrow o, a
            json_infix o, a, '->'
          end

          def visit_Mobility_Plugins_Arel_Nodes_JsonDashDoubleArrow o, a
            # for MySQL we need to re-quote the JSON key name, otherwise it will break on keys like `pt-BR`
            # https://dev.mysql.com/doc/refman/8.0/en/json-search-functions.html#operator_json-inline-path
            unless o.right.value.to_s.start_with?('$.')
              o.right = o.right.class.new(%Q($."#{o.right.value}"))
            end
            json_infix o, a, '->>'
          end

          private

          def json_infix o, a, opr
            visit(Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new(opr, o.left, o.right)), a)
          end
        end
      end

      ::Arel::Visitors::PostgreSQL.include Visitors::PostgreSQL
      ::Arel::Visitors::MySQL.include Visitors::MySQL
    end
  end
end
