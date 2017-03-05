Sequel::Model.db = DB

class Post < Sequel::Model
  extend Mobility
  translates :title, backend: :key_value, cache: true, locale_accessors: true, dirty: true, type: :string
  translates :content, backend: :key_value, cache: true, locale_accessors: true, dirty: true, type: :text
end

class FallbackPost < Sequel::Model
  extend Mobility
  translates :title, :content, backend: :key_value, cache: true, locale_accessors: true, dirty: true, fallbacks: true
end

class MultitablePost < Sequel::Model
  extend Mobility
  translates :title,
    backend:          :table,
    table_name:       :multitable_post_translations,
    association_name: :model_translations
  translates :foo,
    backend:          :table,
    table_name:       :multitable_post_foo_translations,
    association_name: :model_foo_translations
end
