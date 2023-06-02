# frozen-string-literal: true
require "mobility/plugins/arel"

module Mobility
  module Plugins
    module Arel
      module Nodes
        %w[
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

        # Needed for AR 4.2, can be removed when support is deprecated
        if ::ActiveRecord::VERSION::STRING < '5.0'
          [JsonbDashDoubleArrow, HstoreDashArrow].each do |klass|
            klass.class_eval do
              def quoted_node other
                other && super
              end
            end
          end
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

        def json_infix o, a, opr
          visit(Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new(opr, o.left, o.right)), a)
        end
      end

      ::Arel::Visitors::PostgreSQL.include Visitors
    end
  end
end
