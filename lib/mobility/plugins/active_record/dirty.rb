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

=end
      module Dirty
        class MethodsBuilder < ActiveModel::Dirty::MethodsBuilder
          if ::ActiveRecord::VERSION::STRING >= '5.1' # define patterns added in 5.1
            def initialize(*attribute_names)
              super

              define_ar_dirty_methods(attribute_names)
            end
          end
          # @param [Attributes] attributes
          def included(model_class)
            super

            model_class.include InstanceMethods
          end

          private

          def define_ar_dirty_methods(attribute_names)
            m = self

            attribute_names.each do |name|
              define_method "saved_change_to_#{name}?" do
                mutations_before_last_save_from_mobility.changed?(m.append_locale(name))
              end

              define_method "saved_change_to_#{name}" do
                mutations_before_last_save_from_mobility.change_to_attribute(m.append_locale(name))
              end

              define_method "#{name}_before_last_save" do
                mutations_before_last_save_from_mobility.original_value(m.append_locale(name))
              end

              define_method "will_save_change_to_#{name}?" do
                mutations_from_mobility.changed?(m.append_locale(name))
              end

              define_method "#{name}_change_to_be_saved" do
                mutations_from_mobility.change_to_attribute(m.append_locale(name))
              end

              define_method "#{name}_in_database" do
                mutations_from_mobility.original_value(m.append_locale(name))
              end
            end
          end

          module InstanceMethods
            if ::ActiveRecord::VERSION::STRING >= '5.1' # define patterns added in 5.1
              def saved_changes
                mutations_before_last_save_from_mobility.changes
              end

              def changes_to_save
                super.merge(mutations_from_mobility.changes)
              end

              def changed_attribute_names_to_save
                super + mutations_from_mobility.changed_attribute_names
              end

              def attributes_in_database
                super.merge(mutations_from_mobility.changed_values)
              end

              if ::ActiveRecord::VERSION::STRING >= '6.0'
                def has_changes_to_save?
                  super || mutations_from_mobility.any_changes?
                end
              end
            end

            def reload(*)
              super.tap do
                @mutations_from_mobility = nil
                @mutations_before_last_save_from_mobility = nil
              end
            end
          end
        end

        BackendMethods = ActiveModel::Dirty::BackendMethods
      end
    end
  end
end
