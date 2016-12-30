class Post < ActiveRecord::Base
  extend Mobility
  translates :title, backend: :table, cache: true, locale_accessors: true, dirty: true
  translates :content, backend: :table, cache: true, locale_accessors: true, dirty: true, table_class: Mobility::ActiveRecord::StringTranslation
  translates :subtitle, backend: :table, cache: true, locale_accessors: true, dirty: true
end

class FallbackPost < ActiveRecord::Base
  extend Mobility
  translates :title, :content, backend: :table, cache: true, locale_accessors: true, dirty: true, fallbacks: true
end
