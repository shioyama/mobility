require "mobility/backends/sequel/query_methods"

module Mobility
  module Backends
    class Sequel::Serialized::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, _)
        super
        cond_checker = Backends::Serialized.attr_checker(self)

        define_method :where do |*cond, &block|
          cond_checker.call(cond.first) || super(*cond, &block)
        end
      end
    end
  end
end
