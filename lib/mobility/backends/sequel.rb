# frozen_string_literal: true
require "mobility/backend"

module Mobility
  module Backends
    module Sequel
      def self.included(backend_class)
        backend_class.include(Backend)
        backend_class.extend(ClassMethods)
      end

      module ClassMethods
        # @param [Symbol] name Attribute name
        # @param [Symbol] locale Locale
        def [](name, locale)
          build_op(name.to_s, locale)
        end

        # @param [String] _attr Attribute name
        # @param [Symbol] _locale Locale
        # @return Op for this translated attribute
        def build_op(_attr, _locale)
          raise NotImplementedError
        end

        # @param [Sequel::Dataset] dataset Dataset to prepare
        # @param [Object] predicate Predicate
        # @param [Symbol] locale Locale
        # @return [Sequel::Dataset] Prepared dataset
        def prepare_dataset(dataset, _predicate, _locale)
          dataset
        end
      end
    end
  end
end
