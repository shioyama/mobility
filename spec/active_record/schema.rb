module Mobility
  module Test
    if ENV['RAILS_VERSION'] == '4.2'
      parent_class = ::ActiveRecord::Migration
    else
      parent_class = ::ActiveRecord::Migration[[::ActiveRecord::VERSION::MAJOR, ::ActiveRecord::VERSION::MINOR].join(".")]
    end
    class Schema < parent_class
      class << self
        def up
          create_table "posts" do |t|
            t.boolean :published
          end

          create_table "post_metadatas" do |t|
            t.string  :metadata
            t.integer :post_id
          end

          create_table "fallback_posts" do |t|
            t.boolean :published
          end

          create_table "articles" do |t|
            t.string :slug
            t.boolean :published
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
          end

          create_table "article_translations" do |t|
            t.string :locale
            t.integer :article_id
            t.string :title
            t.text :content
          end

          create_table "multitable_posts" do |t|
            t.string :slug
            t.boolean :published
          end

          create_table "multitable_post_translations" do |t|
            t.string :locale
            t.integer :multitable_post_id
            t.string :title
          end

          create_table "multitable_post_foo_translations" do |t|
            t.string :locale
            t.integer :multitable_post_id
            t.string :foo
          end

          create_table "mobility_string_translations" do |t|
            t.string  :locale,            null: false
            t.string  :key,               null: false
            t.string  :value,             null: false
            t.integer :translatable_id,   null: false
            t.string  :translatable_type, null: false
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
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
          end

          create_table "serialized_posts" do |t|
            t.text :title
            t.text :content
            t.boolean :published
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
          end

          if ENV['DB'] == 'postgres'
            create_table "jsonb_posts" do |t|
              if ::ActiveRecord::VERSION::STRING < '5.0'
                t.jsonb :title, default: '{}'
                t.jsonb :content, default: '{}'
              else
                t.jsonb :title, default: ''
                t.jsonb :content, default: ''
              end
              t.boolean :published
              t.datetime "created_at", null: false
              t.datetime "updated_at", null: false
            end

            execute "CREATE EXTENSION IF NOT EXISTS hstore"

            create_table "hstore_posts" do |t|
              t.hstore :title, default: ''
              t.hstore :content, default: ''
              t.boolean :published
              t.datetime "created_at", null: false
              t.datetime "updated_at", null: false
            end
          end
        end
      end
    end
  end
end
