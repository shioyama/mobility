module Mobility
  module Test
    class Schema < ::ActiveRecord::Migration[[::ActiveRecord::VERSION::MAJOR, ::ActiveRecord::VERSION::MINOR].join(".")]
      class << self
        def up
          create_table "posts" do |t|
            t.boolean :published
          end

          create_table "fallback_posts" do |t|
            t.boolean :published
          end

          create_table "articles" do |t|
            t.string :slug
          end

          create_table "mobility_translations" do |t|
            t.string  :locale
            t.string  :key
            t.text    :value
            t.integer :translatable_id
            t.string  :translatable_type
          end

          create_table "comments" do |t|
            t.text :content_en
            t.text :content_ja
            t.text :content_pt_br
            t.text :content_ru
          end
        end
      end
    end
  end
end
