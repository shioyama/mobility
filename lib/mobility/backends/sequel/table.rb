# frozen_string_literal: true
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/table"
require "mobility/sequel/model_translation"
require "mobility/sequel/sql"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Table} backend for Sequel models.

=end
    class Sequel::Table
      include Sequel
      include Table

      def translation_class
        self.class.translation_class
      end

      class << self
        # @return [Symbol] class for translations
        def translation_class
          @translation_class ||= model_class.const_get(subclass_name)
        end

        # @!group Backend Configuration
        # @option options [Symbol] association_name (:translations) Name of association method
        # @option options [Symbol] table_name Name of translation table
        # @option options [Symbol] foreign_key Name of foreign key
        # @option options [Symbol] subclass_name Name of subclass to append to model class to generate translation class
        # @raise [CacheRequired] if cache option is false
        def configure(options)
          raise CacheRequired, "Cache required for Sequel::Table backend" if options[:cache] == false
          table_name = Util.singularize(options[:model_class].table_name)
          options[:table_name]  ||= :"#{table_name}_translations"
          options[:foreign_key] ||= Util.foreign_key(Util.camelize(table_name.downcase))
          if association_name = options[:association_name]
            options[:subclass_name] ||= Util.camelize(Util.singularize(association_name))
          else
            options[:association_name] = :translations
            options[:subclass_name] ||= :Translation
          end
          %i[table_name foreign_key association_name subclass_name].each { |key| options[key] = options[key].to_sym }
        end
        # @!endgroup

        # @param [Symbol] name Attribute name
        # @param [Symbol] locale Locale
        # @return [Sequel::SQL::QualifiedIdentifier]
        def build_op(attr, locale)
          ::Mobility::Sequel::SQL::QualifiedIdentifier.new(table_alias(locale), attr, locale, self, attribute_name: attr)
        end

        # @param [Sequel::Dataset] dataset Dataset to prepare
        # @param [Object] predicate Predicate
        # @param [Symbol] locale Locale
        # @return [Sequel::Dataset] Prepared dataset
        def prepare_dataset(dataset, predicate, locale)
          join_translations(dataset, locale, visit(predicate, locale))
        end

        private

        def join_translations(dataset, locale, join_type)
          if joins = dataset.opts[:join]
            return dataset if joins.any? { |clause| clause.table_expr.alias == table_alias(locale) }
          end
          dataset.join_table(join_type,
                             translation_class.table_name,
                             {
                               locale: locale.to_s,
                               foreign_key => ::Sequel[model_class.table_name][:id]
                             },
                             table_alias: table_alias(locale))
        end

        # @return [Symbol] Join type
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
            nil
          end
        end

        def visit_collection(collection, locale)
          collection.map { |obj|
            visit(obj, locale).tap do |visited|
              return visited if visited == :inner
            end
          }.compact.first
        end

        def visit_sql_identifier(identifier, locale)
          (table_alias(locale) == identifier.table) && :inner || nil
        end

        def visit_boolean(boolean, locale)
          if boolean.op == :'='
            boolean.args.any? { |op| visit(op, locale) } && :inner || nil
          elsif boolean.op == :IS
            boolean.args.any?(&:nil?) && :left_outer || nil
          elsif boolean.op == :OR
            boolean.args.any? { |op| visit(op, locale) } && :left_outer || nil
          else
            visit(boolean.args, locale)
          end
        end
      end

      setup do |attributes, options|
        association_name = options[:association_name]
        subclass_name    = options[:subclass_name]

        translation_class =
          if self.const_defined?(subclass_name, false)
            const_get(subclass_name, false)
          else
            const_set(subclass_name, Class.new(::Sequel::Model(options[:table_name]))).tap do |klass|
              klass.include ::Mobility::Sequel::ModelTranslation
            end
          end

        one_to_many association_name,
          class:      translation_class.name,
          key:        options[:foreign_key],
          reciprocal: :translated_model

        translation_class.many_to_one :translated_model,
          class:      name,
          key:        options[:foreign_key],
          reciprocal: association_name

        plugin :association_dependencies, association_name => :destroy

        callback_methods = Module.new do
          define_method :after_save do
            super()
            cache_accessor = instance_variable_get(:"@__mobility_#{association_name}_cache")
            cache_accessor.each_value do |translation|
              translation.id ? translation.save : send("add_#{Util.singularize(association_name)}", translation)
            end if cache_accessor
          end
        end
        include callback_methods

        include Mobility::Sequel::ColumnChanges.new(attributes)
      end

      def translation_for(locale, _)
        translation = model.send(association_name).find { |t| t.locale == locale.to_s }
        translation ||= translation_class.new(locale: locale)
        translation
      end

      module Cache
        include Table::Cache

        private

        def translations
          (model.send(association_name) + cache.values).uniq
        end
      end

      class CacheRequired < ::StandardError; end
    end

    register_backend(:sequel_table, Sequel::Table)
  end
end
