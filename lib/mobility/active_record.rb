module Mobility
=begin

Module loading ActiveRecord-specific classes for Mobility models.

=end
  module ActiveRecord
    autoload :BackendResetter,   "mobility/active_record/backend_resetter"
    autoload :ModelTranslation,  "mobility/active_record/model_translation"
    autoload :StringTranslation, "mobility/active_record/string_translation"
    autoload :TextTranslation,   "mobility/active_record/text_translation"
    autoload :Translation,       "mobility/active_record/translation"

    def changes_applied
      @previously_changed = changes
      super
    end

    def clear_changes_information
      @previously_changed = ActiveSupport::HashWithIndifferentAccess.new
      super
    end

    def previous_changes
      super.merge(@previously_changed ||= ActiveSupport::HashWithIndifferentAccess.new)
    end

    def self.included(model_class)
      model_class.extend(ClassMethods)
    end

    module ClassMethods
      # @return [ActiveRecord::Relation] relation extended with Mobility query methods.
      define_method ::Mobility.query_method do
        all
      end
    end
  end
end
