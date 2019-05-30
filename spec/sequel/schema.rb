require "sequel/extensions/migration"
Sequel::Model.plugin :timestamps, update_on_create: true

module Mobility
  module Test
    class Schema
      class << self
        def migrate(*)
          DB.create_table? :posts do
            primary_key :id
            TrueClass   :published
            DateTime    :created_at, allow_null: false
            DateTime    :updated_at, allow_null: false
          end

          DB.create_table? :post_metadatas do
            primary_key :id
            String      :metadata
            Integer     :post_id,    allow_null: false
            DateTime    :created_at, allow_null: false
            DateTime    :updated_at, allow_null: false
          end

          DB.create_table? :articles do
            primary_key :id
            String      :slug
            TrueClass   :published
            DateTime    :created_at, allow_null: false
            DateTime    :updated_at, allow_null: false
          end

          DB.create_table? :article_translations do
            primary_key :id
            Integer     :article_id, allow_null: false
            String      :locale,     allow_null: false
            String      :title
            String      :subtitle
            String      :content, text: true
            DateTime    :created_at, allow_null: false
            DateTime    :updated_at, allow_null: false
          end

          DB.create_table? :multitable_posts do
            primary_key :id
            TrueClass   :published
            DateTime    :created_at, allow_null: false
            DateTime    :updated_at, allow_null: false
          end

          DB.create_table? :multitable_post_translations do
            primary_key :id
            Integer     :multitable_post_id, allow_null: false
            String      :locale,             allow_null: false
            String      :title
            DateTime    :created_at,         allow_null: false
            DateTime    :updated_at,         allow_null: false
          end


          DB.create_table? :multitable_post_foo_translations do
            primary_key :id
            Integer     :multitable_post_id, allow_null: false
            String      :locale,             allow_null: false
            String      :foo
            DateTime    :created_at,         allow_null: false
            DateTime    :updated_at,         allow_null: false
          end

          DB.create_table? :mobility_text_translations do
            primary_key :id
            String      :locale,            allow_null: false
            String      :key
            String      :value
            Integer     :translatable_id,   allow_null: false
            String      :translatable_type, allow_null: false
            DateTime    :created_at,        allow_null: false
            DateTime    :updated_at,        allow_null: false
            index [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_text_translations_on_keys
            index [:translatable_id, :translatable_type, :key], name: :index_mobility_text_translations_on_translatable_attribute
          end

          DB.create_table? :mobility_string_translations do
            primary_key :id
            String      :locale,            allow_null: false
            String      :key,               allow_null: false
            String      :value
            Integer     :translatable_id,   allow_null: false
            String      :translatable_type, allow_null: false
            DateTime    :created_at,        allow_null: false
            DateTime    :updated_at,        allow_null: false
            index [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_string_translations_on_keys
            index [:translatable_id, :translatable_type, :key], name: :index_mobility_string_translations_on_translatable_attribute
            index [:translatable_type, :key, :value, :locale], name: :index_mobility_string_translations_on_query_keys
          end

          DB.create_table? :comments do
            primary_key :id
            String      :content_en,    text: true
            String      :content_ja,    text: true
            String      :content_pt_br, text: true
            String      :content_ru,    text: true
            String      :author_en
            String      :author_ja
            String      :author_pt_br
            String      :author_ru
            TrueClass   :published
            Integer     :article_id
            DateTime    :created_at, allow_null: false
            DateTime    :updated_at, allow_null: false
          end

          DB.create_table? :serialized_posts do
            primary_key :id
            String      :my_title_i18n,   text: true
            String      :my_content_i18n, text: true
            TrueClass   :published
            DateTime    :created_at,                   allow_null: false
            DateTime    :updated_at,                   allow_null: false
          end

          if ENV['DB'] == 'postgres'
            DB.create_table? :jsonb_posts do
              primary_key :id
              jsonb       :my_title_i18n,   default: '{}', allow_null: false
              jsonb       :my_content_i18n, default: '{}', allow_null: false
              TrueClass   :published
              DateTime    :created_at,                     allow_null: false
              DateTime    :updated_at,                     allow_null: false
            end

            DB.create_table? :json_posts do
              primary_key :id
              json        :my_title_i18n,   default: '{}', allow_null: false
              json        :my_content_i18n, default: '{}', allow_null: false
              TrueClass   :published
              DateTime    :created_at,                     allow_null: false
              DateTime    :updated_at,                     allow_null: false
            end

            DB.create_table? :container_posts do
              primary_key :id
              jsonb       :translations, default: '{}',    allow_null: false
              TrueClass   :published
              DateTime    :created_at,                     allow_null: false
              DateTime    :updated_at,                     allow_null: false
            end

            DB.run "CREATE EXTENSION IF NOT EXISTS hstore"
            DB.create_table? :hstore_posts do
              primary_key :id
              hstore      :my_title_i18n, default: '',   allow_null: false
              hstore      :my_content_i18n, default: '', allow_null: false
              TrueClass   :published
              DateTime    :created_at,                   allow_null: false
              DateTime    :updated_at,                   allow_null: false
            end
          end
        end

        def up
          migrate(:up)
        end
      end
    end
  end
end
