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
        # @note Only want to define this once, even if multiple QueryMethods
        #   modules are included, so define it here in extended method
        def extended(relation)
          unless relation.methods(false).include?(:mobility_where_chain)
            relation.define_singleton_method(:mobility_where_chain) do
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
