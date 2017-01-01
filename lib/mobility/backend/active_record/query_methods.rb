module Mobility
  module Backend
    module ActiveRecord
      class QueryMethods < Module
        def extended(relation)
          model_class = relation.model

          unless model_class.const_defined?(:MobilityWhereChain)
            relation.define_singleton_method :where do |opts = :chain, *rest|
              opts == :chain ? self.const_get(:MobilityWhereChain).new(spawn) : super(opts, *rest)
            end
            model_class.const_set(:MobilityWhereChain, Class.new(::ActiveRecord::QueryMethods::WhereChain))
          end
        end
      end
    end
  end
end
