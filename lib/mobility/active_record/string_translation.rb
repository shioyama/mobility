# frozen_string_literal: true
require "mobility/active_record/translation"

module Mobility
  module ActiveRecord
    class StringTranslation < Translation
      self.table_name = "mobility_string_translations"
    end
  end
end
