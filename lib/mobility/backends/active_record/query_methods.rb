module Mobility
  module Backends
    module ActiveRecord
=begin

Defines query method overrides to handle translated attributes for ActiveRecord
models. For details see backend-specific subclasses.

=end
      class QueryMethods < Module
        # @param [Array<String>] attributes Translated attributes
        def initialize(attributes, _)
          @attributes = attributes

          attributes.each do |attribute|
            define_method :"find_by_#{attribute}" do |value|
              find_by(attribute.to_sym => value)
            end
          end
        end

        # @param [ActiveRecord::Relation] relation Relation being extended
        # @note Only want to define this once, even if multiple QueryMethods
        #   modules are included, so include it here into the singleton class.
        def extended(relation)
          relation.singleton_class.include WhereChainable
        end

        def extract_attributes(opts)
          opts.is_a?(Hash) && (opts.keys.map(&:to_s) & @attributes).presence
        end

        def collapse(value)
          value.is_a?(Array) ? value.uniq : value
        end
      end

      module WhereChainable
        def where(opts = :chain, *rest)
          opts == :chain ? mobility_where_chain.new(spawn) : super
        end

        def mobility_where_chain
          @mobility_where_chain ||= Class.new(::ActiveRecord::QueryMethods::WhereChain)
        end
      end
      private_constant :QueryMethods, :WhereChainable
    end
  end
end
