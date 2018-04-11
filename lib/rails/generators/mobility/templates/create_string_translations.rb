class CreateStringTranslations < <%= activerecord_migration_class %>

  def change
    create_table :mobility_string_translations do |t|
      t.string  :locale,            null: false
      t.string  :key,               null: false
      t.string  :value
      t.integer :translatable_id,   null: false
      t.string  :translatable_type, null: false
      t.timestamps                  null: false
    end
    add_index :mobility_string_translations, [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_string_translations_on_keys
    add_index :mobility_string_translations, [:translatable_id, :translatable_type, :key], name: :index_mobility_string_translations_on_translatable_attribute
    add_index :mobility_string_translations, [:translatable_type, :key, :value, :locale], name: :index_mobility_string_translations_on_query_keys
  end
end
