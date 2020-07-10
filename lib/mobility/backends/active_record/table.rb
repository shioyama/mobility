# frozen-string-literal: true
require "mobility/backends/active_record"
require "mobility/backends/table"
require "mobility/active_record/model_translation"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Table} backend for ActiveRecord models.

To generate a translation table for a model +Post+, you can use the included
+mobility:translations+ generator:

  rails generate mobility:translations post title:string content:text

This will create a migration which can be run to create the translation table.
If the translation table already exists, it will create a migration adding
columns to that table.

@example Model with table backend
  class Post < ApplicationRecord
    extend Mobility
    translates :title, backend: :table
  end

  post = Post.create(title: "foo")
  #<Post:0x00... id: 1>

  post.title
  #=> "foo"

  post.translations
  #=> [#<Post::Translation:0x00...
  #  id: 1,
  #  locale: "en",
  #  post_id: 1,
  #  title: "foo">]

  Post::Translation.first
  #=> #<Post::Translation:0x00...
  #  id: 1,
  #  locale: "en",
  #  post_id: 1,
  #  title: "foo">

@example Model with multiple translation tables
  class Post < ActiveRecord::Base
    extend Mobility
    translates :title,   backend: :table, table_name: :post_title_translations,   association_name: :title_translations
    translates :content, backend: :table, table_name: :post_content_translations, association_name: :content_translations
  end

  post = Post.create(title: "foo", content: "bar")
  #<Post:0x00... id: 1>

  post.title
  #=> "foo"

  post.content
  #=> "bar"

  post.title_translations
  #=> [#<Post::TitleTranslation:0x00...
  #  id: 1,
  #  locale: "en",
  #  post_id: 1,
  #  title: "foo">]

  post.content_translations
  #=> [#<Post::ContentTranslation:0x00...
  #  id: 1,
  #  locale: "en",
  #  post_id: 1,
  #  content: "bar">]

  Post::TitleTranslation.first
  #=> #<Post::TitleTranslation:0x00...
  #  id: 1,
  #  locale: "en",
  #  post_id: 1,
  #  title: "foo">

  Post::ContentTranslation.first
  #=> #<Post::ContentTranslation:0x00...
  #  id: 1,
  #  locale: "en",
  #  post_id: 1,
  #  title: "bar">
=end
    class ActiveRecord::Table
      include ActiveRecord
      include Table

      class << self
        # @!group Backend Configuration
        # @option options [Symbol] association_name (:translations)
        #   Name of association method
        # @option options [Symbol] table_name Name of translation table
        # @option options [Symbol] foreign_key Name of foreign key
        # @option options [Symbol] subclass_name (:Translation) Name of subclass
        #   to append to model class to generate translation class
        def configure(options)
          table_name = options[:model_class].table_name
          options[:table_name]  ||= "#{table_name.singularize}_translations"
          options[:foreign_key] ||= table_name.downcase.singularize.camelize.foreign_key
          if (association_name = options[:association_name]).present?
            options[:subclass_name] ||= association_name.to_s.singularize.camelize.freeze
          else
            options[:association_name] = :translations
            options[:subclass_name] ||= :Translation
          end
          %i[foreign_key association_name subclass_name table_name].each { |key| options[key] = options[key].to_sym }
        end
        # @!endgroup

        # @param [String] attr Attribute name
        # @param [Symbol] _locale Locale
        # @return [Mobility::Arel::Attribute] Arel node for column on translation table
        def build_node(attr, locale)
          aliased_table = model_class.const_get(subclass_name).arel_table.alias(table_alias(locale))
          Arel::Attribute.new(aliased_table, attr, locale, self)
        end

        # Joins translations using either INNER/OUTER join appropriate to the
        # query.
        # @param [ActiveRecord::Relation] relation Relation to scope
        # @param [Object] predicate Arel predicate
        # @param [Symbol] locale (Mobility.locale) Locale
        # @option [Boolean] invert
        # @return [ActiveRecord::Relation] relation Relation with joins applied (if needed)
        def apply_scope(relation, predicate, locale = Mobility.locale, invert: false)
          visitor = Visitor.new(self, locale)
          if join_type = visitor.accept(predicate)
            join_type &&= Visitor::INNER_JOIN if invert
            join_translations(relation, locale, join_type)
          else
            relation
          end
        end

        private

        def join_translations(relation, locale, join_type)
          return relation if already_joined?(relation, locale, join_type)
          m = model_class.arel_table
          t = model_class.const_get(subclass_name).arel_table.alias(table_alias(locale))
          relation.joins(m.join(t, join_type).
                         on(t[foreign_key].eq(m[:id]).
                            and(t[:locale].eq(locale))).join_sources)
        end

        def already_joined?(relation, locale, join_type)
          if join = get_join(relation, locale)
            return true if (join_type == Visitor::OUTER_JOIN) || (Visitor::INNER_JOIN === join)
            relation.joins_values = relation.joins_values - [join]
          end
          false
        end

        def get_join(relation, locale)
          relation.joins_values.find { |v| (::Arel::Nodes::Join === v) && (v.left.name == table_alias(locale).to_s) }
        end
      end

      # Internal class used to visit all nodes in a predicate clause and
      # return a single join type required for the predicate, or nil if no
      # join is required. (Similar to the KeyValue Visitor class.)
      #
      # Example:
      #
      #   class Post < ApplicationRecord
      #     extend Mobility
      #     translates :title, :content, backend: :table
      #   end
      #
      #   backend_class = Post.mobility_backend_class(:title)
      #   visitor = Mobility::Backends::ActiveRecord::Table::Visitor.new(backend_class, :en)
      #
      #   title   = backend_class.build_node("title", :en)   # arel node for title
      #   content = backend_class.build_node("content", :en) # arel node for content
      #
      #   visitor.accept(title.eq(nil).and(content.eq(nil)))
      #   #=> Arel::Nodes::OuterJoin
      #
      #   visitor.accept(title.eq("foo").and(content.eq(nil)))
      #   #=> Arel::Nodes::InnerJoin
      #
      # In the first case, both attributes are matched against nil values, so
      # we need an OUTER JOIN. In the second case, one attribute is matched
      # against a non-nil value, so we can use an INNER JOIN.
      #
      class Visitor < Arel::Visitor
        private

        def visit_Arel_Nodes_Equality(object)
          nils, nodes = [object.left, object.right].partition(&:nil?)
          if nodes.any?(&method(:visit))
            nils.empty? ? INNER_JOIN : OUTER_JOIN
          end
        end

        def visit_collection(objects)
          objects.map { |obj|
            visit(obj).tap { |visited| return visited if visited == INNER_JOIN }
          }.compact.first
        end
        alias :visit_Array :visit_collection

        # If either left or right is an OUTER JOIN (predicate with a NULL
        # argument) OR we are combining this with anything other than a
        # column on the same translation table, we need to OUTER JOIN
        # here. The *only* case where we can use an INNER JOIN is when we
        # have predicates like this:
        #
        #   table.attribute1 = 'something' OR table.attribute2 = 'somethingelse'
        #
        # Here, both columns are on the same table, and both are non-nil, so
        # we can safely INNER JOIN. This is pretty subtle, think about it.
        #
        def visit_Arel_Nodes_Or(object)
          visited = [object.left, object.right].map(&method(:visit))
          if visited.all? { |v| INNER_JOIN == v }
            INNER_JOIN
          elsif visited.any?
            OUTER_JOIN
          end
        end

        def visit_Mobility_Arel_Attribute(object)
          # We compare table names here to ensure that attributes defined on
          # different backends but the same table will correctly get an OUTER
          # join when required. Use options[:table_name] here since we don't
          # know if the other backend has a +table_name+ option accessor.
          (backend_class.table_name == object.backend_class.options[:table_name]) &&
            (locale == object.locale) && OUTER_JOIN || nil
        end
      end

      setup do |_attributes, options|
        association_name = options[:association_name]
        subclass_name    = options[:subclass_name]

        translation_class =
          if self.const_defined?(subclass_name, false)
            const_get(subclass_name, false)
          else
            const_set(subclass_name, Class.new(Mobility::ActiveRecord::ModelTranslation))
          end

        translation_class.table_name = options[:table_name]

        has_many association_name,
          class_name:  translation_class.name,
          foreign_key: options[:foreign_key],
          dependent:   :destroy,
          autosave:    true,
          inverse_of:  :translated_model,
          extend:      TranslationsHasManyExtension

        translation_class.belongs_to :translated_model,
          class_name:  name,
          foreign_key: options[:foreign_key],
          inverse_of:  association_name,
          touch: true

        before_save do
          required_attributes = translation_class.attribute_names.select { |name| self.class.mobility_attribute?(name) }
          send(association_name).destroy_empty_translations(required_attributes)
        end

        module_name = "MobilityArTable#{association_name.to_s.camelcase}"
        unless const_defined?(module_name)
          dupable = Module.new do
            define_method :initialize_dup do |source|
              super(source)
              self.send("#{association_name}=", source.send(association_name).map(&:dup))
            end
          end
          include const_set(module_name, dupable)
        end
      end

      # Returns translation for a given locale, or builds one if none is present.
      # @param [Symbol] locale
      def translation_for(locale, _)
        translation = translations.in_locale(locale)
        translation ||= translations.build(locale: locale)
        translation
      end

      module TranslationsHasManyExtension
        # Returns translation in a given locale, or nil if none exist
        # @param [Symbol, String] locale
        def in_locale(locale)
          locale = locale.to_s
          find { |t| t.locale == locale }
        end

        # Destroys translations with all empty values
        def destroy_empty_translations(required_attributes)
          empty_translations = select{ |t| required_attributes.map(&t.method(:send)).none? }
          destroy(empty_translations) if empty_translations.any?
        end
      end
    end

    register_backend(:active_record_table, ActiveRecord::Table)
  end
end
