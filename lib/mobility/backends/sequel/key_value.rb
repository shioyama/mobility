# frozen-string-literal: true
require "set"
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/key_value"

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
        rescue NameError
          raise ArgumentError, "You must define a Mobility::Sequel::#{type.capitalize}Translation class."
        end
        # @!endgroup

        def build_op(attr, locale)
          QualifiedIdentifier.new(table_alias(attr, locale), value_column, locale, self, attr)
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

        # Called from setup block. Can be overridden to customize behaviour.
        def define_one_to_many_association(klass, attributes)
          belongs_to_id     = :"#{belongs_to}_id"
          belongs_to_type   = :"#{belongs_to}_type"

          # Track all attributes for this association, so that we can limit the scope
          # of keys for the association to only these attributes. We need to track the
          # attributes assigned to the association in case this setup code is called
          # multiple times, so we don't "forget" earlier attributes.
          #
          attrs_method_name = :"#{association_name}_attributes"
          association_attributes = (klass.instance_variable_get(:"@#{attrs_method_name}") || []) + attributes
          klass.instance_variable_set(:"@#{attrs_method_name}", association_attributes)

          klass.one_to_many association_name,
            reciprocal:      belongs_to,
            key:             belongs_to_id,
            reciprocal_type: :one_to_many,
            conditions:      { belongs_to_type => klass.to_s, key_column => association_attributes },
            adder:           proc { |translation| translation.update(belongs_to_id => pk, belongs_to_type => self.class.to_s) },
            remover:         proc { |translation| translation.update(belongs_to_id => nil, belongs_to_type => nil) },
            clearer:         proc { send_(:"#{association_name}_dataset").update(belongs_to_id => nil, belongs_to_type => nil) },
            class:           class_name
        end

        # Called from setup block. Can be overridden to customize behaviour.
        def define_save_callbacks(klass, attributes)
          b = self
          callback_methods = Module.new do
            define_method :before_save do
              super()
              send(b.association_name).select { |t| attributes.include?(t.__send__(b.key_column)) && Util.blank?(t.__send__(b.value_column)) }.each(&:destroy)
            end
            define_method :after_save do
              super()
              attributes.each { |attribute| mobility_backends[attribute].save_translations }
            end
          end
          klass.include callback_methods
        end

        # Called from setup block. Can be overridden to customize behaviour.
        def define_after_destroy_callback(klass)
          # Clean up *all* leftover translations of this model, only once.
          b = self
          translation_classes = [class_name, *Mobility::Backends::Sequel::KeyValue::Translation.descendants].uniq
          klass.define_method :after_destroy do
            super()

            @mobility_after_destroy_translation_classes = [] unless defined?(@mobility_after_destroy_translation_classes)
            (translation_classes - @mobility_after_destroy_translation_classes).each do |translation_class|
              translation_class.where(:"#{b.belongs_to}_id" => id, :"#{b.belongs_to}_type" => self.class.name).destroy
            end
            @mobility_after_destroy_translation_classes += translation_classes
          end
        end

        private

        def join_translations(dataset, attr, locale, join_type)
          dataset.join_table(join_type,
                             class_name.table_name,
                             {
                               key_column => attr.to_s,
                               :locale => locale.to_s,
                               :"#{belongs_to}_type" => model_class.name,
                               :"#{belongs_to}_id" => ::Sequel[:"#{model_class.table_name}"][:id]
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
          when ::Sequel::SQL::ComplexExpression
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

      setup do |attributes, _options, backend_class|
        backend_class.define_one_to_many_association(self, attributes)
        backend_class.define_save_callbacks(self, attributes)
        backend_class.define_after_destroy_callback(self)

        include(mod = Module.new)
        backend_class.define_column_changes(mod, attributes)
      end

      # Returns translation for a given locale, or initializes one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::Backends::Sequel::KeyValue::TextTranslation,Mobility::Backends::Sequel::KeyValue::StringTranslation]
      def translation_for(locale, **)
        translation = model.send(association_name).find { |t| t.__send__(key_column) == attribute && t.locale == locale.to_s }
        translation ||= class_name.new(locale: locale, key_column => attribute)
        translation
      end

      # Saves translation which have been built and which have non-blank values.
      def save_translations
        cache.each_value do |translation|
          next unless present?(translation.__send__ value_column)
          translation.id ? translation.save : model.send("add_#{singularize(association_name)}", translation)
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

      class Translatable < Module
        attr_reader :key_column, :value_column, :belongs_to, :id_column, :type_column

        def initialize(key_column, value_column, belongs_to)
          @key_column = key_column
          @value_column = value_column
          @belongs_to = belongs_to
          @id_column = :"#{belongs_to}_id"
          @type_column = :"#{belongs_to}_type"
        end

        # Strictly these are not "descendants", but to keep terminology
        # consistent with ActiveRecord KeyValue backend.
        def descendants
          @descendants ||= Set.new
        end

        def included(base)
          @descendants ||= Set.new
          @descendants << base

          mod = self
          key_column = mod.key_column
          id_column = mod.id_column
          type_column = mod.type_column

          base.class_eval do
            plugin :validation_helpers

            # Paraphased from sequel_polymorphic gem
            #
            model = underscore(self.to_s)
            plural_model = pluralize(model)
            many_to_one mod.belongs_to,
              reciprocal: plural_model.to_sym,
              reciprocal_type: :many_to_one,
              setter: (proc do |able_instance|
                self[id_column]   = (able_instance.pk if able_instance)
                self[type_column] = (able_instance.class.name if able_instance)
              end),
              dataset: (proc do
                translatable_type = send type_column
                translatable_id   = send id_column
                return if translatable_type.nil? || translatable_id.nil?
                klass = self.class.send(:constantize, translatable_type)
                klass.where(klass.primary_key => translatable_id)
              end),
              eager_loader: (proc do |eo|
                id_map = {}
                eo[:rows].each do |model|
                  model_able_type = model.send type_column
                  model_able_id = model.send id_column
                  model.associations[belongs_to] = nil
                  ((id_map[model_able_type] ||= {})[model_able_id] ||= []) << model if !model_able_type.nil? && !model_able_id.nil?
                end
                id_map.each do |klass_name, id_map|
                  klass = constantize(camelize(klass_name))
                  klass.where(klass.primary_key=>id_map.keys).all do |related_obj|
                    id_map[related_obj.pk].each do |model|
                      model.associations[belongs_to] = related_obj
                    end
                  end
                end
              end)

            define_method :validate do
              super()
              validates_presence [:locale, key_column, id_column, type_column]
              validates_unique   [:locale, key_column, id_column, type_column]
            end
          end
        end
      end
      Translation = Translatable.new(:key, :value, :translatable)

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
