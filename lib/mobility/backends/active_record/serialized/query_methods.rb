require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Serialized::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, _)
        super
        opts_checker = @opts_checker = Backends::Serialized.attr_checker(self)

        define_method :where! do |opts, *rest|
          opts_checker.call(opts) || super(opts, *rest)
        end
      end

      def extended(relation)
        super
        opts_checker = @opts_checker

        mod = Module.new do
          define_method :not do |opts, *rest|
            opts_checker.call(opts) || super(opts, *rest)
          end
        end
        relation.mobility_where_chain.include(mod)
      end
    end
  end
end
