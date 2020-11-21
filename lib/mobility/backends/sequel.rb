# frozen_string_literal: true
require "mobility/backend"

module Mobility
  module Backends
    module Sequel
      def self.included(backend_class)
        backend_class.include Backend
        backend_class.extend ClassMethods
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

        # Forces Sequel to notice changes when Mobility setter method is
        # called.
        # TODO: Find a better way to do this.
        def define_column_changes(mod, attributes, column_affix: "%s")
          mod.class_eval do
            attributes.each do |attribute|
              define_method "#{attribute}=" do |value, **options|
                if !options[:super] && send(attribute) != value
                  locale = options[:locale] || Mobility.locale
                  column = (column_affix % attribute).to_sym
                  attribute_with_locale = :"#{attribute}_#{Mobility.normalize_locale(locale)}"
                  @changed_columns = changed_columns | [column, attribute.to_sym, attribute_with_locale]
                end
                super(value, **options)
              end
            end
          end
        end
      end
    end
  end
end
