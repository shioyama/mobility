class <%= migration_class_name %> < <%= activerecord_migration_class %>
  def change
    create_table :<%= table_name %><%= primary_key_type if respond_to?(:primary_key_type) %> do |t|

      # Translated attribute(s)
<% attributes.each do |attribute| -%>
<% if attribute.respond_to?(:token?) && attribute.token? -%>
      t.string :<%= attribute.name %><%= attribute.inject_options %>
<% else -%>
      t.<%= attribute.type %> :<%= attribute.name %><%= attribute.inject_options %>
<% end -%>
<% end -%>

      t.string  :locale, null: false
      t.references :<%=model_table_name.singularize %>, null: false, foreign_key: true

      t.timestamps null: false
    end

    add_index :<%= table_name %>, :locale, name: :<%= translation_index_name("locale") %>
    add_index :<%= table_name %>, [:<%= foreign_key %>, :locale], name: :<%= translation_index_name(foreign_key, "locale") %>, unique: true

<%- attributes_with_index.each do |attribute| -%>
  add_index :<%= table_name %>, [:<%= attribute.index_name %><%= attribute.inject_index_options %>, :locale], name: :<%= translation_index_name(attribute.index_name, "locale") %>
<%- end -%>
  end
end
