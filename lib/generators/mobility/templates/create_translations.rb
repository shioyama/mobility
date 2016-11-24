class CreateTranslations < ActiveRecord::Migration

  def change
    create_table :mobility_translations do |t|
      t.string   :locale
      t.string   :key
      t.text     :value
      t.integer  :translatable_id
      t.string   :translatable_type
      t.timestamps
    end
    add_index :mobility_translations, [:translatable_id, :translatable_type, :locale, :key], unique: true, name: :index_mobility_translations_on_keys
    add_index :mobility_translations, [:translatable_id, :translatable_type], name: :index_mobility_translations_on_translatable
  end
end
