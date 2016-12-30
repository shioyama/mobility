Sequel::Model.db = DB

class Post < Sequel::Model
  plugin :dirty
  extend Mobility
  translates :title, backend: :table, cache: true, locale_accessors: true, dirty: true, type: :string
  translates :content, backend: :table, cache: true, locale_accessors: true, dirty: true, type: :text
end

class FallbackPost < Sequel::Model
  plugin :dirty
  extend Mobility
  translates :title, :content, backend: :table, cache: true, locale_accessors: true, dirty: true, fallbacks: true
end
