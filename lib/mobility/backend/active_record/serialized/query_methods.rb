module Mobility
  module Backend
    class ActiveRecord::Serialized::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        opts_checker = @opts_checker = lambda do |opts|
          if opts.is_a?(Hash) && (opts.keys.map(&:to_s) & attributes).present?
            raise ArgumentError, "You cannot query on mobility attributes translated with the Serialized backend."
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
        relation.model.const_get(:MobilityWhereChain).prepend(mod)
      end
    end
  end
end
