module Mobility
  module Backend
    class ActiveRecord::Serialized::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **)
        super
        attributes_extractor = @attributes_extractor
        opts_checker = @opts_checker = lambda do |opts|
          if keys = attributes_extractor.call(opts)
            raise ArgumentError,
              "You cannot query on mobility attributes translated with the Serialized backend (#{keys.join(", ")})."
          end
        end

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
