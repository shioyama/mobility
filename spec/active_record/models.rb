class Post < ActiveRecord::Base
  extend Mobility
  translates :title, :content, backend: :table, cache: true, locale_accessors: true, dirty: true
end

class FallbackPost < ActiveRecord::Base
  extend Mobility
  translates :title, :content, backend: :table, cache: true, locale_accessors: true, dirty: true, fallbacks: true
end
