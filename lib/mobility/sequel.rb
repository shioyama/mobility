module Mobility
  module Sequel
    autoload :Translation,       "mobility/sequel/translation"
    autoload :TextTranslation,   "mobility/sequel/text_translation"
    autoload :StringTranslation, "mobility/sequel/string_translation"
    autoload :BackendResetter,   "mobility/sequel/backend_resetter"

    def self.included(model_class)
      model_class.extend(ClassMethods)
    end

    module ClassMethods
      def i18n
        dataset
      end
    end
  end
end
