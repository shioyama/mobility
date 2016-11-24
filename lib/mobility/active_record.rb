module Mobility
  module ActiveRecord
    autoload :Translation, "mobility/active_record/translation"

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
  end
end
