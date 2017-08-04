require "mobility/sequel/translation"

module Mobility
  module Sequel
    class StringTranslation < ::Sequel::Model(:mobility_string_translations)
      include Translation
    end
  end
end
