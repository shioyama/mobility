class CreateTextTranslations < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]

  def change
    create_table :mobility_text_translations do |t|
      t.string  :locale
      t.string  :key
      t.text    :value
      t.integer :translatable_id
      t.string  :translatable_type
      t.timestamps
    end
    add_index :mobility_text_translations, [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_text_translations_on_keys
    add_index :mobility_text_translations, [:translatable_id, :translatable_type, :key], name: :index_mobility_text_translations_on_translatable_attribute
    add_index :mobility_text_translations, [:translatable_type, :key, :value, :locale], name: :index_mobility_text_translations_on_query_keys
  end
end
