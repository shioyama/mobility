# frozen-string-literal: true
module Mobility
  module Arel
    module Nodes
      class Unary  < ::Arel::Nodes::Unary;  end
      class Binary < ::Arel::Nodes::Binary; end
      class Grouping < ::Arel::Nodes::Grouping; end
      class Equality < ::Arel::Nodes::Equality; end

      ::Arel::Visitors::ToSql.class_eval do
        alias :visit_Mobility_Arel_Nodes_Equality :visit_Arel_Nodes_Equality
        alias :visit_Mobility_Arel_Nodes_Grouping :visit_Arel_Nodes_Grouping
      end
    end
  end
end
