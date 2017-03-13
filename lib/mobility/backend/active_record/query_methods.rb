module Mobility
  module Backend
    module ActiveRecord
=begin

Defines query method overrides to handle translated attributes for ActiveRecord
models. For details see backend-specific subclasses.

=end
      class QueryMethods < Module
        # @param [Array<String>] attributes Translated attributes
        def initialize(attributes, **_)
          @attributes = attributes
          @attributes_extractor = lambda do |opts|
            opts.is_a?(Hash) && (opts.keys.map(&:to_s) & attributes).presence
          end
        end

        # @param [ActiveRecord::Relation] relation Relation being extended
        def extended(relation)
          model_class = relation.model
          unless model_class.respond_to?(:mobility_where_chain)
            model_class.define_singleton_method(:mobility_where_chain) do
              @mobility_where_chain ||= Class.new(::ActiveRecord::QueryMethods::WhereChain)
            end

            relation.define_singleton_method :where do |opts = :chain, *rest|
              opts == :chain ? mobility_where_chain.new(spawn) : super(opts, *rest)
            end
          end
        end
      end
    end
  end
end
