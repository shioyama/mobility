class <%= migration_class_name %> < <%= activerecord_migration_class %>
  def change
    create_table :<%= table_name %><%= primary_key_type %> do |t|

      # Translated attribute(s)
<% attributes.each do |attribute| -%>
<% if attribute.token? -%>
      t.string :<%= attribute.name %><%= attribute.inject_options %>
<% else -%>
      t.<%= attribute.type %> :<%= attribute.name %><%= attribute.inject_options %>
<% end -%>
<% end -%>

      t.string  :locale, null: false
      t.integer :<%= foreign_key %>, null: false

      t.timestamps null: false
    end

    add_index :<%= table_name %>, :<%= foreign_key %>, name: :<%= translation_index_name %>
    add_index :<%= table_name %>, :locale, name: :<%= translation_locale_index_name %>
    add_index :<%= table_name %>, [:<%= foreign_key %>, :locale], name: :<%= translation_unique_index_name %>, unique: true

<%- attributes_with_index.each do |attribute| -%>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
<%- end -%>
  end
end
