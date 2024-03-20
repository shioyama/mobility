module Mobility
  module Test
    class Schema < ::ActiveRecord::Migration[[::ActiveRecord::VERSION::MAJOR, ::ActiveRecord::VERSION::MINOR].join(".")]
      class << self
        def up
          create_table "posts" do |t|
            t.boolean :published
            t.timestamps null: false
          end

          create_table "articles" do |t|
            t.string :slug
            t.boolean :published
            t.timestamps null: false
          end

          create_table "article_translations" do |t|
            t.string :locale
            t.integer :article_id
            t.string :title
            t.string :subtitle
            t.text :content
            t.timestamps null: false
          end

          create_table "article_foo_translations" do |t|
            t.string :locale
            t.integer :article_id
            t.string :foo
            t.timestamps null: false
          end

          create_table "mobility_string_translations" do |t|
            t.string  :locale,            null: false
            t.string  :key,               null: false
            t.string  :value,             null: false
            t.integer :translatable_id,   null: false
            t.string  :translatable_type, null: false
            t.timestamps                  null: false
          end
          add_index :mobility_string_translations, [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_string_translations_on_keys
          add_index :mobility_string_translations, [:translatable_id, :translatable_type, :key], name: :index_mobility_string_translations_on_translatable_attribute
          add_index :mobility_string_translations, [:translatable_type, :key, :value, :locale], name: :index_mobility_string_translations_on_query_keys

          create_table "mobility_text_translations" do |t|
            t.string  :locale,            null: false
            t.string  :key,               null: false
            t.text    :value,             null: false
            t.integer :translatable_id,   null: false
            t.string  :translatable_type, null: false
            t.timestamps                  null: false
          end
          add_index :mobility_text_translations, [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_text_translations_on_keys
          add_index :mobility_text_translations, [:translatable_id, :translatable_type, :key], name: :index_mobility_text_translations_on_translatable_attribute

          create_table "comments" do |t|
            t.text :content_en
            t.text :content_ja
            t.text :content_pt_br
            t.text :content_ru
            t.text :author_en
            t.text :author_ja
            t.text :author_pt_br
            t.text :author_ru
            t.boolean :published
            t.integer :article_id
            t.timestamps null: false
          end

          create_table "serialized_posts" do |t|
            t.text :my_title_i18n
            t.text :my_content_i18n
            t.boolean :published
            t.timestamps null: false
          end

          if ENV['DB'] == 'postgres'
            create_table "jsonb_posts" do |t|
              t.jsonb :my_title_i18n, default: {}
              t.jsonb :my_content_i18n, default: {}
              t.boolean :published
              t.timestamps null: false
            end

            create_table "json_posts" do |t|
              t.json :my_title_i18n, default: {}
              t.json :my_content_i18n, default: {}
              t.boolean :published
              t.timestamps null: false
            end

            create_table "container_posts" do |t|
              t.jsonb :translations, default: {}
              t.boolean :published
              t.timestamps null: false
            end

            execute "CREATE EXTENSION IF NOT EXISTS hstore"

            create_table "hstore_posts" do |t|
              t.hstore :my_title_i18n, default: ''
              t.hstore :my_content_i18n, default: ''
              t.boolean :published
              t.timestamps null: false
            end
          end
        end
      end
    end
  end
end
