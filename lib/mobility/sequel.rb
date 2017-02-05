module Mobility
  module Sequel
    autoload :BackendResetter,   "mobility/sequel/backend_resetter"
    autoload :ColumnChanges,     "mobility/sequel/column_changes"
    autoload :ModelTranslation,  "mobility/sequel/model_translation"
    autoload :StringTranslation, "mobility/sequel/string_translation"
    autoload :TextTranslation,   "mobility/sequel/text_translation"
    autoload :Translation,       "mobility/sequel/translation"

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
