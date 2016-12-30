module Mobility
  module ActiveRecord
    autoload :Translation,     "mobility/active_record/translation"
    autoload :BackendResetter, "mobility/active_record/backend_resetter"

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
      def i18n
        all
      end
    end
  end
end
