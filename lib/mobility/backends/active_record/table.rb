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
  class Post < ActiveRecord::Base
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
        # @return [Arel::Attributes::Attribute] Arel node for column on translation table
        def build_node(attr, _locale)
          model_class.const_get(subclass_name).arel_table[attr]
        end

        # Joins translations using either INNER/OUTER join appropriate to the
        # query. So for example, using the Query plugin:
        #
        # Article.i18n.where(title: nil, content: nil)   #=> OUTER JOIN (all nils)
        # Article.i18n.where(title: "foo", content: nil) #=> INNER JOIN (one non-nil)
        #
        # In the first case, if we are in (say) the "en" locale, then we should
        # match articles that have *no* article_translations with English
        # locales (since no translation is equivalent to a nil value). If we
        # used an INNER JOIN in the first case, an article with no English
        # translations would be filtered out, so we use an OUTER JOIN.
        #
        # When deciding whether to use an outer or inner join, array-valued
        # conditions are treated as nil if they have any values.
        #
        # Article.i18n.where(title: nil, content: ["foo", nil])            #=> OUTER JOIN (all nil or array with nil)
        # Article.i18n.where(title: "foo", content: ["foo", nil])          #=> INNER JOIN (one non-nil)
        # Article.i18n.where(title: ["foo", "bar"], content: ["foo", nil]) #=> INNER JOIN (one non-nil array)
        #
        # The logic also applies when a query has more than one where clause.
        #
        # Article.where(title: nil).where(content: nil)   #=> OUTER JOIN (all nils)
        # Article.where(title: nil).where(content: "foo") #=> INNER JOIN (one non-nil)
        # Article.where(title: "foo").where(content: nil) #=> INNER JOIN (one non-nil)
        #
        # @param [ActiveRecord::Relation] relation Relation to scope
        # @param [Hash] opts Hash of options for query
        # @param [Symbol] locale Locale
        # @option [Boolean] invert
        def add_translations(relation, opts, locale, invert:)
          outer_join = require_outer_join?(opts, invert)
          return relation if already_joined?(relation, table_name, outer_join)

          t = model_class.const_get(subclass_name).arel_table
          m = model_class.arel_table
          join_type = outer_join ? ::Arel::Nodes::OuterJoin : ::Arel::Nodes::InnerJoin
          relation.joins(m.join(t, join_type).
                         on(t[foreign_key].eq(m[:id]).
                            and(t[:locale].eq(locale))).join_sources)
        end

        private

        def already_joined?(relation, table_name, outer_join)
          if join = relation.joins_values.find { |v| (::Arel::Nodes::Join === v) && (v.left.name == table_name.to_s) }
            return true if outer_join || ::Arel::Nodes::InnerJoin === join
            relation.joins_values = relation.joins_values - [join]
          end
          false
        end

        def require_outer_join?(opts, invert)
          !invert && opts.values.compact.all? { |v| ![*v].all? }
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
          required_attributes = self.class.mobility_attributes & translation_class.attribute_names
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
          each { |t| destroy(t) if required_attributes.map(&t.method(:send)).none? }
        end
      end
    end
  end
end
