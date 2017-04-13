module Mobility
=begin

Module loading Sequel-specific classes for Mobility models.

=end
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
      # @return [Sequel::Dataset] dataset extended with Mobility query methods.
      define_method ::Mobility.query_method do
        dataset
      end
    end
  end
end
