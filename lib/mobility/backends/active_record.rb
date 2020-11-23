# frozen_string_literal: true
require "mobility/backend"
require "mobility/plugins/arel"

module Mobility
  module Backends
    module ActiveRecord
      def self.included(backend_class)
        backend_class.include(Backend)
        backend_class.extend(ClassMethods)
      end

      module ClassMethods
        # @param [Symbol] name Attribute name
        # @param [Symbol] locale Locale
        def [](name, locale)
          build_node(name.to_s, locale)
        end

        # @param [String] _attr Attribute name
        # @param [Symbol] _locale Locale
        # @return Arel node for this translated attribute
        def build_node(_attr, _locale)
          raise NotImplementedError
        end

        # @param [ActiveRecord::Relation] relation Relation to scope
        # @param [Object] predicate Arel predicate
        # @param [Symbol] locale (Mobility.locale) Locale
        # @option [Boolean] invert
        # @return [ActiveRecord::Relation] Relation with scope added
        def apply_scope(relation, _predicate, _locale = Mobility.locale, invert: false)
          relation
        end

        private

        def build_quoted(value)
          ::Arel::Nodes.build_quoted(value)
        end
      end
    end
  end
end
