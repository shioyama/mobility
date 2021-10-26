# frozen-string-literal: true
require "mobility/backends/active_record"
require "mobility/backends/key_value"

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
            options[:class_name]       ||= const_get("#{type.capitalize}Translation")
          end
        rescue NameError
          raise ArgumentError, "You must define a Mobility::Backends::ActiveRecord::KeyValue::#{type.capitalize}Translation class."
        end
        # @!endgroup

        # @param [String] attr Attribute name
        # @param [Symbol] _locale Locale
        # @return [Mobility::Plugins::Arel::Attribute] Arel attribute for aliased
        #   translation table value column
        def build_node(attr, locale)
          aliased_table = class_name.arel_table.alias(table_alias(attr, locale))
          Plugins::Arel::Attribute.new(aliased_table, value_column, locale, self, attr.to_sym)
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

        # Called from setup block. Can be overridden to customize behaviour.
        def define_has_many_association(klass, attributes)
          # Track all attributes for this association, so that we can limit the scope
          # of keys for the association to only these attributes. We need to track the
          # attributes assigned to the association in case this setup code is called
          # multiple times, so we don't "forget" earlier attributes.
          #
          attrs_method_name = :"__#{association_name}_attributes"
          association_attributes = (klass.instance_variable_get(:"@#{attrs_method_name}") || []) + attributes
          klass.instance_variable_set(:"@#{attrs_method_name}", association_attributes)

          b = self

          klass.has_many association_name, ->{ where b.key_column => association_attributes },
            as: belongs_to,
            class_name: class_name.name,
            inverse_of: belongs_to,
            autosave:   true
        end

        # Called from setup block. Can be overridden to customize behaviour.
        def define_initialize_dup(klass)
          b = self
          module_name = "MobilityArKeyValue#{association_name.to_s.camelcase}"
          unless const_defined?(module_name)
            callback_methods = Module.new do
              define_method :initialize_dup do |source|
                super(source)
                self.send("#{b.association_name}=", source.send(b.association_name).map(&:dup))
                # Set inverse on associations
                send(b.association_name).each do |translation|
                  translation.send(:"#{b.belongs_to}=", self)
                end
              end
            end
            klass.include const_set(module_name, callback_methods)
          end
        end

        # Called from setup block. Can be overridden to customize behaviour.
        def define_before_save_callback(klass)
          b = self
          klass.before_save do
            send(b.association_name).select { |t| t.send(b.value_column).blank? }.each do |translation|
              send(b.association_name).destroy(translation)
            end
          end
        end

        # Called from setup block. Can be overridden to customize behaviour.
        def define_after_destroy_callback(klass)
          # Ensure we only call after destroy hook once per translations class
          b = self
          translation_classes = [class_name, *Mobility::Backends::ActiveRecord::KeyValue::Translation.descendants].uniq
          klass.after_destroy do
            @mobility_after_destroy_translation_classes = [] unless defined?(@mobility_after_destroy_translation_classes)
            (translation_classes - @mobility_after_destroy_translation_classes).each do |translation_class|
              translation_class.where(b.belongs_to => self).destroy_all
            end
            @mobility_after_destroy_translation_classes += translation_classes
          end
        end

        private

        def join_translations(relation, key, locale, join_type)
          return relation if already_joined?(relation, key, locale, join_type)
          m = model_class.arel_table
          t = class_name.arel_table.alias(table_alias(key, locale))
          relation.joins(m.join(t, join_type).
                         on(t[key_column].eq(key).
                            and(t[:locale].eq(locale).
                                and(t[:"#{belongs_to}_type"].eq(model_class.base_class.name).
                                    and(t[:"#{belongs_to}_id"].eq(m[model_class.primary_key] || m[:id]))))).join_sources)
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
      class Visitor < Plugins::Arel::Visitor
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

        def visit_Mobility_Plugins_Arel_Attribute(object)
          if object.backend_class == backend_class && object.locale == locale
            { object.attribute_name => OUTER_JOIN }
          end
        end

        def visit_default(_)
          {}
        end
      end

      setup do |attributes, _options, backend_class|
        backend_class.define_has_many_association(self, attributes)
        backend_class.define_initialize_dup(self)
        backend_class.define_before_save_callback(self)
        backend_class.define_after_destroy_callback(self)
      end

      # Returns translation for a given locale, or builds one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::Backends::ActiveRecord::KeyValue::TextTranslation,Mobility::Backends::ActiveRecord::KeyValue::StringTranslation]
      def translation_for(locale, **)
        translation = translations.find do |t|
          t.send(key_column) == attribute && t.locale == locale.to_s
        end
        translation ||= translations.build(locale: locale, key_column => attribute)
        translation
      end

      class Translation < ::ActiveRecord::Base
        self.abstract_class = true

        belongs_to :translatable, polymorphic: true, touch: true

        validates :key, presence: true, uniqueness: { scope: [:translatable_id, :translatable_type, :locale], case_sensitive: true }
        validates :translatable, presence: true
        validates :locale, presence: true
      end

      class TextTranslation < Translation
        self.table_name = "mobility_text_translations"
      end

      class StringTranslation < Translation
        self.table_name = "mobility_string_translations"
      end
    end

    register_backend(:active_record_key_value, ActiveRecord::KeyValue)
  end
end
