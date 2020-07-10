# frozen-string-literal: true
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/key_value"
require "mobility/sequel/column_changes"
require "mobility/sequel/hash_initializer"
require "mobility/sequel/string_translation"
require "mobility/sequel/text_translation"
require "mobility/sequel/sql"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::KeyValue} backend for Sequel models.

@note This backend requires the cache to be enabled in order to track
  and store changed translations, since Sequel does not support +build+-type
  methods on associations like ActiveRecord.

=end
    class Sequel::KeyValue
      include Sequel
      include KeyValue
      include Util

      class << self
        # @!group Backend Configuration
        # @option (see Mobility::Backends::KeyValue::ClassMethods#configure)
        # @raise (see Mobility::Backends::KeyValue::ClassMethods#configure)
        # @raise [CacheRequired] if cache is disabled
        def configure(options)
          raise CacheRequired, "Cache required for Sequel::KeyValue backend" if options[:cache] == false
          super
          if type = options[:type]
            options[:association_name] ||= :"#{options[:type]}_translations"
            options[:class_name]       ||= Mobility::Sequel.const_get("#{type.capitalize}Translation")
          end
          options[:table_alias_affix] = "#{options[:model_class]}_%s_#{options[:association_name]}"
        rescue NameError
          raise ArgumentError, "You must define a Mobility::Sequel::#{type.capitalize}Translation class."
        end
        # @!endgroup

        def build_op(attr, locale)
          ::Mobility::Sequel::SQL::QualifiedIdentifier.new(table_alias(attr, locale), :value, locale, self, attribute_name: attr)
        end

        # @param [Sequel::Dataset] dataset Dataset to prepare
        # @param [Object] predicate Predicate
        # @param [Symbol] locale Locale
        # @return [Sequel::Dataset] Prepared dataset
        def prepare_dataset(dataset, predicate, locale)
          visit(predicate, locale).inject(dataset) do |ds, (attr, join_type)|
            join_translations(ds, attr, locale, join_type)
          end
        end

        private

        def join_translations(dataset, attr, locale, join_type)
          dataset.join_table(join_type,
                             class_name.table_name,
                             {
                               key: attr.to_s,
                               locale: locale.to_s,
                               translatable_type: model_class.name,
                               translatable_id: ::Sequel[:"#{model_class.table_name}"][:id]
                             },
                             table_alias: table_alias(attr, locale))
        end

        # @return [Hash] Hash of attribute/join_type pairs
        def visit(predicate, locale)
          case predicate
          when Array
            visit_collection(predicate, locale)
          when ::Mobility::Sequel::SQL::QualifiedIdentifier
            visit_sql_identifier(predicate, locale)
          when ::Sequel::SQL::BooleanExpression
            visit_boolean(predicate, locale)
          when ::Sequel::SQL::Expression
            visit(predicate.args, locale)
          else
            {}
          end
        end

        def visit_boolean(boolean, locale)
          if boolean.op == :IS
            nils, ops = boolean.args.partition(&:nil?)
            if hash = visit(ops, locale)
              join_type = nils.empty? ? :inner : :left_outer
              # TODO: simplify to hash.transform_values { join_type } when
              #   support for Ruby 2.3 is deprecated
              ::Hash[hash.keys.map { |key| [key, join_type] }]
            else
              {}
            end
          elsif boolean.op == :'='
            hash = visit(boolean.args, locale)
            # TODO: simplify to hash.transform_values { :inner } when
            #   support for Ruby 2.3 is deprecated
            ::Hash[hash.keys.map { |key| [key, :inner] }]
          elsif boolean.op == :OR
            hash = boolean.args.map { |op| visit(op, locale) }.
              compact.inject(:merge)
            # TODO: simplify to hash.transform_values { :left_outer } when
            #   support for Ruby 2.3 is deprecated
            ::Hash[hash.keys.map { |key| [key, :left_outer] }]
          else
            visit(boolean.args, locale)
          end
        end

        def visit_collection(collection, locale)
          collection.map { |p| visit(p, locale) }.compact.inject do |hash, visited|
            visited.merge(hash) { |_, old, new| old == :inner ? old : new }
          end
        end

        def visit_sql_identifier(identifier, locale)
          if identifier.backend_class == self && identifier.locale == locale
            { identifier.attribute_name => :left_outer }
          else
            {}
          end
        end
      end

      setup do |attributes, options|
        association_name   = options[:association_name]
        translations_class = options[:class_name]

        attrs_method_name = :"#{association_name}_attributes"
        association_attributes = (instance_variable_get(:"@#{attrs_method_name}") || []) + attributes
        instance_variable_set(:"@#{attrs_method_name}", association_attributes)

        one_to_many association_name,
          reciprocal:      :translatable,
          key:             :translatable_id,
          reciprocal_type: :one_to_many,
          conditions:      { translatable_type: self.to_s, key: association_attributes },
          adder:           proc { |translation| translation.update(translatable_id: pk, translatable_type: self.class.to_s) },
          remover:         proc { |translation| translation.update(translatable_id: nil, translatable_type: nil) },
          clearer:         proc { send(:"#{association_name}_dataset").update(translatable_id: nil, translatable_type: nil) },
          class:           translations_class

        callback_methods = Module.new do
          define_method :before_save do
            super()
            send(association_name).select { |t| attributes.include?(t.key) && Util.blank?(t.value) }.each(&:destroy)
          end
          define_method :after_save do
            super()
            attributes.each { |attribute| mobility_backends[attribute].save_translations }
          end
        end
        include callback_methods

        include DestroyKeyValueTranslations
        include Mobility::Sequel::ColumnChanges.new(attributes)
      end

      # Returns translation for a given locale, or initializes one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::Sequel::TextTranslation,Mobility::Sequel::StringTranslation]
      def translation_for(locale, _)
        translation = model.send(association_name).find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= class_name.new(locale: locale, key: attribute)
        translation
      end

      # Saves translation which have been built and which have non-blank values.
      def save_translations
        cache.each_value do |translation|
          next unless present?(translation.value)
          translation.id ? translation.save : model.send("add_#{singularize(association_name)}", translation)
        end
      end

      # Clean up *all* leftover translations of this model, only once.
      module DestroyKeyValueTranslations
        def after_destroy
          super
          [:string, :text].freeze.each do |type|
            Mobility::Sequel.const_get("#{type.capitalize}Translation").
              where(translatable_id: id, translatable_type: self.class.name).destroy
          end
        end
      end

      class CacheRequired < ::StandardError; end

      module Cache
        include KeyValue::Cache

        private

        def translations
          (model.send(association_name) + cache.values).uniq
        end
      end
    end

    register_backend(:sequel_key_value, Sequel::KeyValue)
  end
end
