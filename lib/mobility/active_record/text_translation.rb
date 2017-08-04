require "mobility/active_record/translation"

module Mobility
  module ActiveRecord
    class TextTranslation < Translation
      self.table_name = "mobility_text_translations"
    end
  end
end
