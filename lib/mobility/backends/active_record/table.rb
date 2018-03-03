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

      require 'mobility/backends/active_record/table/query_methods'

      # @!group Backend Configuration
      # @option options [Symbol] association_name (:translations)
      #   Name of association method
      # @option options [Symbol] table_name Name of translation table
      # @option options [Symbol] foreign_key Name of foreign key
      # @option options [Symbol] subclass_name (:Translation) Name of subclass
      #   to append to model class to generate translation class
      def self.configure(options)
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
          inverse_of:  :translated_model

        translation_class.belongs_to :translated_model,
          class_name:  name,
          foreign_key: options[:foreign_key],
          inverse_of:  association_name,
          touch: true

        before_save { mobility_destroy_empty_table_translations(association_name) }

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

        include DestroyEmptyTranslations
      end

      setup_query_methods(QueryMethods)

      def translation_for(locale, _)
        translation = translations.find { |t| t.locale == locale.to_s }
        translation ||= translations.build(locale: locale)
        translation
      end

      module DestroyEmptyTranslations
        private

        def mobility_destroy_empty_table_translations(association_name)
          send(association_name).each do |t|
            attrs = t.attribute_names & self.class.translated_attribute_names
            send(association_name).destroy(t) if attrs.map(&t.method(:send)).none?
          end
        end
      end
    end
  end
end
