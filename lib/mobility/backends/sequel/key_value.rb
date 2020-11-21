# frozen-string-literal: true
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/key_value"
require "mobility/sequel/hash_initializer"

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
            options[:class_name]       ||= const_get("#{type.capitalize}Translation")
          end
          options[:table_alias_affix] = "#{model_class}_%s_#{options[:association_name]}"
        rescue NameError
          raise ArgumentError, "You must define a Mobility::Sequel::#{type.capitalize}Translation class."
        end
        # @!endgroup

        def build_op(attr, locale)
          QualifiedIdentifier.new(table_alias(attr, locale), :value, locale, self, attr)
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
          when QualifiedIdentifier
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

      backend = self

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
        include(mod = Module.new)
        backend.define_column_changes(mod, attributes)
      end

      # Returns translation for a given locale, or initializes one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::Backends::Sequel::KeyValue::TextTranslation,Mobility::Backends::Sequel::KeyValue::StringTranslation]
      def translation_for(locale, **)
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
            Mobility::Backends::Sequel::KeyValue.const_get("#{type.capitalize}Translation").
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

      class QualifiedIdentifier < ::Sequel::SQL::QualifiedIdentifier
        attr_reader :backend_class, :locale, :attribute_name

        def initialize(table, column, locale, backend_class, attribute_name)
          @backend_class = backend_class
          @locale = locale
          @attribute_name = attribute_name || column
          super(table, column)
        end
      end

      module Translation
        def self.included(base)
          base.class_eval do
            plugin :validation_helpers

            # Paraphased from sequel_polymorphic gem
            #
            model = underscore(self.to_s)
            plural_model = pluralize(model)
            many_to_one :translatable,
              reciprocal: plural_model.to_sym,
              reciprocal_type: :many_to_one,
              setter: (proc do |able_instance|
                self[:translatable_id]   = (able_instance.pk if able_instance)
                self[:translatable_type] = (able_instance.class.name if able_instance)
              end),
              dataset: (proc do
                translatable_type = send :translatable_type
                translatable_id   = send :translatable_id
                return if translatable_type.nil? || translatable_id.nil?
                klass = self.class.send(:constantize, translatable_type)
                klass.where(klass.primary_key => translatable_id)
              end),
              eager_loader: (proc do |eo|
                id_map = {}
                eo[:rows].each do |model|
                  model_able_type = model.send :translatable_type
                  model_able_id = model.send :translatable_id
                  model.associations[:translatable] = nil
                  ((id_map[model_able_type] ||= {})[model_able_id] ||= []) << model if !model_able_type.nil? && !model_able_id.nil?
                end
                id_map.each do |klass_name, id_map|
                  klass = constantize(camelize(klass_name))
                  klass.where(klass.primary_key=>id_map.keys).all do |related_obj|
                    id_map[related_obj.pk].each do |model|
                      model.associations[:translatable] = related_obj
                    end
                  end
                end
              end)

            def validate
              super
              validates_presence [:locale, :key, :translatable_id, :translatable_type]
              validates_unique   [:locale, :key, :translatable_id, :translatable_type]
            end
          end
        end
      end

      class TextTranslation < ::Sequel::Model(:mobility_text_translations)
        include Translation
      end

      class StringTranslation < ::Sequel::Model(:mobility_string_translations)
        include Translation
      end
    end

    register_backend(:sequel_key_value, Sequel::KeyValue)
  end
end
