module Mobility
  module Test
    class Schema < ::ActiveRecord::Migration[[::ActiveRecord::VERSION::MAJOR, ::ActiveRecord::VERSION::MINOR].join(".")]
      class << self
        def up
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
        end
      end
    end
  end
end
