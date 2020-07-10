# frozen-string-literal: true
require "mobility/backends/active_record"
require "mobility/backends/key_value"
require "mobility/active_record/string_translation"
require "mobility/active_record/text_translation"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::KeyValue} backend for ActiveRecord models.

@example
  class Post < ApplicationRecord
    extend Mobility
    translates :title, backend: :key_value, association_name: :translations, type: :string
  end

  post = Post.create(title: "foo")
  post.translations
  #=> #<ActiveRecord::Associations::CollectionProxy ... >
  post.translations.first.value
  #=> "foo"
  post.translations.first.class
  #=> Mobility::ActiveRercord::StringTranslation

=end
    class ActiveRecord::KeyValue
      include ActiveRecord
      include KeyValue

      class << self
        # @!group Backend Configuration
        # @option (see Mobility::Backends::KeyValue::ClassMethods#configure)
        # @raise (see Mobility::Backends::KeyValue::ClassMethods#configure)
        def configure(options)
          super
          if type = options[:type]
            options[:association_name] ||= :"#{options[:type]}_translations"
            options[:class_name]       ||= Mobility::ActiveRecord.const_get("#{type.capitalize}Translation")
          end
          options[:table_alias_affix] = "#{options[:model_class]}_%s_#{options[:association_name]}"
        rescue NameError
          raise ArgumentError, "You must define a Mobility::ActiveRecord::#{type.capitalize}Translation class."
        end
        # @!endgroup

        # @param [String] attr Attribute name
        # @param [Symbol] _locale Locale
        # @return [Mobility::Arel::Attribute] Arel attribute for aliased
        #   translation table value column
        def build_node(attr, locale)
          aliased_table = class_name.arel_table.alias(table_alias(attr, locale))
          Arel::Attribute.new(aliased_table, :value, locale, self, attribute_name: attr.to_sym)
        end

        # Joins translations using either INNER/OUTER join appropriate to the query.
        # @param [ActiveRecord::Relation] relation Relation to scope
        # @param [Object] predicate Arel predicate
        # @param [Symbol] locale (Mobility.locale) Locale
        # @option [Boolean] invert
        # @return [ActiveRecord::Relation] relation Relation with joins applied (if needed)
        def apply_scope(relation, predicate, locale = Mobility.locale, invert: false)
          visitor = Visitor.new(self, locale)
          visitor.accept(predicate).inject(relation) do |rel, (attr, join_type)|
            join_type &&= ::Arel::Nodes::InnerJoin if invert
            join_translations(rel, attr, locale, join_type)
          end
        end

        private

        def join_translations(relation, key, locale, join_type)
          return relation if already_joined?(relation, key, locale, join_type)
          m = model_class.arel_table
          t = class_name.arel_table.alias(table_alias(key, locale))
          relation.joins(m.join(t, join_type).
                         on(t[:key].eq(key).
                            and(t[:locale].eq(locale).
                                and(t[:translatable_type].eq(model_class.base_class.name).
                                    and(t[:translatable_id].eq(m[:id]))))).join_sources)
        end

        def already_joined?(relation, name, locale, join_type)
          if join = get_join(relation, name, locale)
            return true if (join_type == ::Arel::Nodes::OuterJoin) || (::Arel::Nodes::InnerJoin === join)
            relation.joins_values = relation.joins_values - [join]
          end
          false
        end

        def get_join(relation, name, locale)
          relation.joins_values.find do |v|
            (::Arel::Nodes::Join === v) && (v.left.name == (table_alias(name, locale)))
          end
        end
      end

      # Internal class used to visit all nodes in a predicate clause and
      # return a hash of key/value pairs corresponding to attributes (keys)
      # and the respective join type (values) required for each attribute.
      #
      # Example:
      #
      #   class Post < ApplicationRecord
      #     extend Mobility
      #     translates :title, :content, backend: :key_value
      #   end
      #
      #   backend_class = Post.mobility_backend_class(:title)
      #   visitor = Mobility::Backends::ActiveRecord::KeyValue::Visitor.new(backend_class, :en)
      #
      #   title   = backend_class.build_node("title", :en)   # arel node for title
      #   content = backend_class.build_node("content", :en) # arel node for content
      #
      #   visitor.accept(title.eq("foo").and(content.eq(nil)))
      #   #=> { title: Arel::Nodes::InnerJoin, content: Arel::Nodes::OuterJoin }
      #
      # The title predicate has a non-nil value, so we can use an INNER JOIN,
      # whereas we are searching for nil content, which requires an OUTER JOIN.
      #
      class Visitor < Arel::Visitor
        private

        def visit_Arel_Nodes_Equality(object)
          nils, nodes = [object.left, object.right].partition(&:nil?)
          if hash = visit_collection(nodes)
            hash.transform_values { nils.empty? ? INNER_JOIN : OUTER_JOIN }
          end
        end

        def visit_collection(objects)
          objects.map(&method(:visit)).compact.inject do |hash, visited|
            visited.merge(hash) { |_, old, new| old == INNER_JOIN ? old : new }
          end
        end
        alias :visit_Array :visit_collection

        def visit_Arel_Nodes_Or(object)
          [object.left, object.right].map(&method(:visit)).compact.inject(:merge).
            transform_values { OUTER_JOIN }
        end

        def visit_Mobility_Arel_Attribute(object)
          if object.backend_class == backend_class && object.locale == locale
            { object.attribute_name => OUTER_JOIN }
          end
        end

        def visit_default(_)
          {}
        end
      end

      setup do |attributes, options|
        association_name   = options[:association_name]
        translations_class = options[:class_name]

        # Track all attributes for this association, so that we can limit the scope
        # of keys for the association to only these attributes. We need to track the
        # attributes assigned to the association in case this setup code is called
        # multiple times, so we don't "forget" earlier attributes.
        #
        attrs_method_name = :"__#{association_name}_attributes"
        association_attributes = (instance_variable_get(:"@#{attrs_method_name}") || []) + attributes
        instance_variable_set(:"@#{attrs_method_name}", association_attributes)

        has_many association_name, ->{ where key: association_attributes },
          as: :translatable,
          class_name: translations_class.name,
          inverse_of: :translatable,
          autosave:   true
        before_save do
          send(association_name).select { |t| t.value.blank? }.each do |translation|
            send(association_name).destroy(translation)
          end
        end

        module_name = "MobilityArKeyValue#{association_name.to_s.camelcase}"
        unless const_defined?(module_name)
          callback_methods = Module.new do
            define_method :initialize_dup do |source|
              super(source)
              self.send("#{association_name}=", source.send(association_name).map(&:dup))
              # Set inverse on associations
              send(association_name).each { |translation| translation.translatable = self }
            end
          end
          include const_set(module_name, callback_methods)
        end

        include DestroyKeyValueTranslations
      end

      # Returns translation for a given locale, or builds one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::ActiveRecord::TextTranslation,Mobility::ActiveRecord::StringTranslation]
      def translation_for(locale, _options = {})
        translation = translations.find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= translations.build(locale: locale, key: attribute)
        translation
      end

      module DestroyKeyValueTranslations
        def self.included(model_class)
          model_class.after_destroy do
            [:string, :text].each do |type|
              Mobility::ActiveRecord.const_get("#{type.capitalize}Translation").
                where(translatable: self).destroy_all
            end
          end
        end
      end
    end

    register_backend(:active_record_key_value, ActiveRecord::KeyValue)
  end
end
