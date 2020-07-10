# frozen-string-literal: true
require "mobility/plugins/active_model/dirty"

module Mobility
  module Plugins
    module ActiveRecord
=begin

Dirty tracking for AR models. See {Mobility::Plugins::ActiveModel::Dirty} for
details on usage.

In addition to methods added by {Mobility::Plugins::ActiveModel::Dirty}, the
AR::Dirty plugin adds support for the following persistence-specific methods
(for a model with a translated attribute +title+):
- +saved_change_to_title?+
- +saved_change_to_title+
- +title_before_last_save+
- +will_save_change_to_title?+
- +title_change_to_be_saved+
- +title_in_database+

The following methods are also patched to include translated attribute changes:
- +saved_changes+
- +has_changes_to_save?+
- +changes_to_save+
- +changed_attribute_names_to_save+
- +attributes_in_database+

In addition, the following ActiveModel attribute handler methods are also
patched to work with translated attributes:
- +saved_change_to_attribute?+
- +saved_change_to_attribute+
- +attribute_before_last_save+
- +will_save_change_to_attribute?+
- +attribute_change_to_be_saved+
- +attribute_in_database+

(When using these methods, you must pass the attribute name along with its
locale suffix, so +title_en+, +title_pt_br+, etc.)

=end
      module Dirty
        extend Plugin

        depends_on :dirty, include: false
        depends_on :active_model_dirty, include: :before

        initialize_hook do
          if options[:dirty]
            include InstanceMethods
          end
        end

        included_hook do |_, backend_class|
          if options[:dirty]
            backend_class.include BackendMethods
          end
        end

        private

        def dirty_handler_methods
          HandlerMethods
        end

        # Module which defines generic ActiveRecord::Dirty handler methods like
        # +attribute_before_last_save+ that are patched to work with translated
        # attributes.
        HandlerMethods = ActiveModel::Dirty::HandlerMethodsBuilder.new(
          Class.new do
            # In earlier versions of Rails, these are needed to avoid an
            # exception when including the AR Dirty module outside of an
            # AR::Base class. Eventually we should be able to drop them.
            def self.after_create; end
            def self.after_update; end

            include ::ActiveRecord::AttributeMethods::Dirty
          end
        )

        module InstanceMethods
          if ::ActiveRecord::VERSION::STRING >= '5.1' # define patterns added in 5.1
            def saved_changes
              super.merge(mutations_from_mobility.previous_changes)
            end

            def changes_to_save
              super.merge(mutations_from_mobility.changes)
            end

            def changed_attribute_names_to_save
              super + mutations_from_mobility.changed
            end

            def attributes_in_database
              super.merge(mutations_from_mobility.changed_attributes)
            end

            if ::ActiveRecord::VERSION::STRING >= '6.0'
              def has_changes_to_save?
                super || mutations_from_mobility.changed?
              end
            end
          end

          def reload(*)
            super.tap do
              @mutations_from_mobility = nil
            end
          end
        end

        BackendMethods = ActiveModel::Dirty::BackendMethods
      end
    end

    register_plugin(:active_record_dirty, ActiveRecord::Dirty)
  end
end
