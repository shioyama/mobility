class <%= migration_class_name %> < <%= activerecord_migration_class %>
  def change
<% attributes.each do |attribute| -%>
  <%- if attribute.reference? -%>
    add_reference :<%= table_name %>, :<%= attribute.name %><%= attribute.inject_options %>
  <%- elsif attribute.respond_to?(:token?) && attribute.token? -%>
    add_column :<%= table_name %>, :<%= attribute.name %>, :string<%= attribute.inject_options %>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>, unique: true
  <%- else -%>
    add_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
    <%- if attribute.has_index? -%>
    add_index :<%= table_name %>, [:<%= attribute.index_name %><%= attribute.inject_index_options %>, :locale]
    <%- end -%>
  <%- end -%>
<% end -%>
  end
end
