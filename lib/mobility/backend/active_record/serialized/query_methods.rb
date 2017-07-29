module Mobility
  module Backend
    class ActiveRecord::Serialized::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, _)
        super
        attributes_extractor = @attributes_extractor
        opts_checker = @opts_checker = Backend::Serialized.attr_checker(attributes_extractor)

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
