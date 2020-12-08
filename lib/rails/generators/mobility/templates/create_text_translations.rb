class CreateTextTranslations < <%= activerecord_migration_class %>
  def change
    create_table :mobility_text_translations do |t|
      t.string :locale, null: false
      t.string :key,    null: false
      t.text :value
      t.references :translatable, polymorphic: true, index: false
      t.timestamps null: false
    end
    add_index :mobility_text_translations, [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_text_translations_on_keys
    add_index :mobility_text_translations, [:translatable_id, :translatable_type, :key], name: :index_mobility_text_translations_on_translatable_attribute
  end
end
