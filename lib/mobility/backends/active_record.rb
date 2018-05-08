module Mobility
  module Backends
    module ActiveRecord
      def self.included(backend_class)
        backend_class.include(Backend)
        backend_class.extend(ClassMethods)
      end

      module ClassMethods
        # @param [String] _attr Attribute name
        # @param [Symbol] _locale Locale
        def build_node(_attr, _locale)
          raise NotImplementedError
        end

        # @param [ActiveRecord::Relation] relation Relation to scope
        # @param [Symbol] locale Locale
        # @option [Boolean] invert
        # @return [ActiveRecord::Relation] Relation with scope added
        def add_translations(relation, _opts, _locale, invert: false)
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
