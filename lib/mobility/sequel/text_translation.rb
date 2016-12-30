module Mobility
  module Sequel
    class TextTranslation < ::Sequel::Model(:mobility_text_translations)
      include Translation
    end
  end
end
