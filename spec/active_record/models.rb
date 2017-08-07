class Post < ActiveRecord::Base
  extend Mobility
  translates :title, backend: :key_value, cache: true, locale_accessors: true, dirty: true, type: :string
  translates :content, backend: :key_value, cache: true, locale_accessors: true, dirty: true, type: :text
end

class FallbackPost < ActiveRecord::Base
  extend Mobility
  translates :title, :content, backend: :key_value, cache: true, locale_accessors: true, dirty: true, fallbacks: true
end

class MultitablePost < ActiveRecord::Base
  extend Mobility
  translates :title,
    backend:          :table,
    table_name:       :multitable_post_translations,
    association_name: :translations
  translates :foo,
    backend:          :table,
    table_name:       :multitable_post_foo_translations,
    association_name: :foo_translations
end
