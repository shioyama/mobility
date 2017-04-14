# frozen-string-literal: true

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Table} backend for ActiveRecord models.

To generate a translation table for a model +Post+, you can use the included
+mobility:translations+ generator:

  rails generate mobility:translations post title:string content:text

This will create a migration which can be run to create the translation table.
If the translation table already exists, it will create a migration adding
columns to that table.

@example Model with table backend
  class Post < ActiveRecord::Base
    translates :title, backend: :table, association_name: :translations
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

      require 'mobility/backend/active_record/table/query_methods'

      # @return [Symbol] name of the association method
      attr_reader :association_name

      # @!macro backend_constructor
      # @option options [Symbol] association_name Name of association
      def initialize(model, attribute, **options)
        super
        @association_name = options[:association_name]
      end

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, **_)
        translation_for(locale).send(attribute)
      end

      # @!macro backend_reader
      def write(locale, value, **_)
        translation_for(locale).tap { |t| t.send("#{attribute}=", value) }.send(attribute)
      end
      # @!endgroup

      # @!group Backend Configuration
      # @option options [Symbol] association_name (:mobility_model_translations)
      #   Name of association method
      # @option options [Symbol] table_name Name of translation table
      # @option options [Symbol] foreign_key Name of foreign key
      # @option options [Symbol] subclass_name (:Translation) Name of subclass
      #   to append to model class to generate translation class
      def self.configure(options)
        table_name = options[:model_class].table_name
        options[:table_name]  ||= "#{table_name.singularize}_translations".freeze
        options[:foreign_key] ||= table_name.downcase.singularize.camelize.foreign_key
        if (association_name = options[:association_name]).present?
          options[:subclass_name] ||= association_name.to_s.singularize.camelize.freeze
        else
          options[:association_name] = :mobility_model_translations
          options[:subclass_name] ||= :Translation
        end
        %i[foreign_key association_name subclass_name].each { |key| options[key] = options[key].to_sym }
      end
      # @!endgroup

      setup do |attributes, options|
        association_name = options[:association_name]
        subclass_name    = options[:subclass_name]

        attr_accessor :"__#{association_name}_cache"

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
          inverse_of:  :translated_model

        translation_class.belongs_to :translated_model,
          class_name:  name,
          foreign_key: options[:foreign_key],
          inverse_of:  association_name
      end

      setup_query_methods(QueryMethods)

      # @!group Cache Methods
      # @return [Table::TranslationsCache]
      def new_cache
        reset_model_cache unless model_cache
        model_cache.for(attribute)
      end

      # @return [Boolean]
      def write_to_cache?
        true
      end

      def clear_cache
        model_cache.try(:clear)
      end
      # @!endgroup

      private

      def translation_for(locale)
        translation = translations.find { |t| t.locale == locale.to_s.freeze }
        translation ||= translations.build(locale: locale)
        translation
      end

      def translations
        model.send(association_name)
      end

      def model_cache
        model.send(:"__#{association_name}_cache")
      end

      def reset_model_cache
        model.send(:"__#{association_name}_cache=",
                   Table::TranslationsCache.new { |locale| translation_for(locale) })
      end
    end
  end
end
