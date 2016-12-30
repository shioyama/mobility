class Post < ActiveRecord::Base
  extend Mobility
  translates :title, backend: :table, cache: true, locale_accessors: true, dirty: true, type: :string
  translates :content, backend: :table, cache: true, locale_accessors: true, dirty: true, type: :text
end

class FallbackPost < ActiveRecord::Base
  extend Mobility
  translates :title, :content, backend: :table, cache: true, locale_accessors: true, dirty: true, fallbacks: true
end
