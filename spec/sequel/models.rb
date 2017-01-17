Sequel::Model.db = DB

class Post < Sequel::Model
  plugin :dirty
  extend Mobility
  translates :title, backend: :key_value, cache: true, locale_accessors: true, dirty: true, type: :string
  translates :content, backend: :key_value, cache: true, locale_accessors: true, dirty: true, type: :text
end

class FallbackPost < Sequel::Model
  plugin :dirty
  extend Mobility
  translates :title, :content, backend: :key_value, cache: true, locale_accessors: true, dirty: true, fallbacks: true
end
