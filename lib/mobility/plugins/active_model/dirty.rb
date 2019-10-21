# frozen-string-literal: true

module Mobility
  module Plugins
    module ActiveModel
=begin

Dirty tracking for models which include the +ActiveModel::Dirty+ module.

Assuming we have an attribute +title+, this module will add support for the
following methods:
- +title_changed?+
- +title_change+
- +title_was+
- +title_will_change!+
- +title_previously_changed?+
- +title_previous_change+
- +restore_title!+

The following methods are also patched to work with translated attributes:
- +changed_attributes+
- +changes+
- +changed+
- +changed?+
- +previous_changes+
- +clear_attribute_changes+
- +restore_attributes+

@see http://api.rubyonrails.org/classes/ActiveModel/Dirty.html Rails documentation for Active Model Dirty module

=end
      module Dirty
        # Builds module which adds suffix/prefix methods for translated
        # attributes so they act like normal dirty-tracked attributes.
        class MethodsBuilder < Module
          def initialize(*attribute_names)
            define_dirty_methods(attribute_names)

            if ::ActiveModel::VERSION::STRING >= '5.0' # methods added in Rails 5.0
              define_ar_5_0_dirty_methods(attribute_names)
            end
          end

          def included(model_class)
            model_class.include InstanceMethods
          end

          def append_locale(attr_name)
            Mobility.normalize_locale_accessor(attr_name)
          end

          private

          def define_dirty_methods(attribute_names)
            m = self

            attribute_names.each do |name|
              define_method "#{name}_changed?" do |**options|
                mutations_from_mobility.changed?(m.append_locale(name), **options)
              end

              define_method "#{name}_change" do
                mutations_from_mobility.change_to_attribute(m.append_locale(name))
              end

              define_method "#{name}_will_change!" do
                mutations_from_mobility.force_change(m.append_locale(name))
              end

              define_method "#{name}_was" do
                mutations_from_mobility.original_value(m.append_locale(name))
              end

              define_method "restore_#{name}!" do
                locale_accessor = m.append_locale(name)
                if mutations_from_mobility.changed?(locale_accessor)
                  __send__("#{name}=", mutations_from_mobility.original_value(locale_accessor))
                  mutations_from_mobility.forget_change(locale_accessor)
                end
              end
            end

            # This private method override is necessary to make
            # +restore_attributes+ (which is public) work with translated
            # attributes.
            define_method :restore_attribute! do |attr|
              attribute_names.include?(attr.to_s) ? send("restore_#{attr}!") : super(attr)
            end
            private :restore_attribute!
          end

          def define_ar_5_0_dirty_methods(attribute_names)
            m = self

            attribute_names.each do |name|
              define_method "#{name}_previously_changed?" do
                mutations_before_last_save_from_mobility.changed?(m.append_locale(name))
              end

              define_method "#{name}_previous_change" do
                mutations_before_last_save_from_mobility.change_to_attribute(m.append_locale(name))
              end
            end
          end

          module InstanceMethods
            def changed_attributes
              super.merge(mutations_from_mobility.changed_values)
            end

            def changes_applied
              super
              @mutations_before_last_save_from_mobility = mutations_from_mobility
              @mutations_from_mobility = nil
            end

            def changes
              super.merge(mutations_from_mobility.changes)
            end

            def changed
              # uniq is required for Rails < 6.0
              (super + mutations_from_mobility.changed_attribute_names).uniq
            end

            def changed?
              super || mutations_from_mobility.any_changes?
            end

            def previous_changes
              super.merge(mutations_before_last_save_from_mobility.changes)
            end

            def clear_changes_information
              @mutations_from_mobility = nil
              @mutations_before_last_save_from_mobility = nil
              super
            end

            private

            def mutations_from_mobility
              @mutations_from_mobility ||= MobilityMutationTracker.new(self)
            end

            def mutations_before_last_save_from_mobility
              @mutations_before_last_save_from_mobility ||= ::ActiveModel::NullMutationTracker.new(self)
            end
          end
        end

        class MobilityMutationTracker
          OPTION_NOT_GIVEN = Object.new

          def initialize(model)
            @model = model
            @forced_changes = {}
          end

          def changed_attribute_names
            attr_names.select { |attr_name| changed?(attr_name) }
          end

          def changed_values
            attr_names.each_with_object({}.with_indifferent_access) do |attr_name, result|
              if changed?(attr_name)
                result[attr_name] = original_value(attr_name)
              end
            end
          end

          def changes
            attr_names.each_with_object({}.with_indifferent_access) do |attr_name, result|
              if change = change_to_attribute(attr_name)
                result.merge!(attr_name => change)
              end
            end
          end

          def change_to_attribute(attr_name)
            if changed?(attr_name)
              [original_value(attr_name), fetch_value(attr_name)]
            end
          end

          def any_changes?
            attr_names.any? { |attr| changed?(attr) }
          end

          def changed?(attr_name, from: OPTION_NOT_GIVEN, to: OPTION_NOT_GIVEN)
            attribute_changed?(attr_name) &&
              (OPTION_NOT_GIVEN == from || original_value(attr_name) == from) &&
              (OPTION_NOT_GIVEN == to || fetch_value(attr_name) == to)
          end

          def forget_change(attr_name)
            forced_changes.delete(attr_name)
          end

          def original_value(attr_name)
            if changed?(attr_name)
              forced_changes[attr_name]
            else
              fetch_value(attr_name)
            end
          end

          def force_change(attr_name)
            forced_changes[attr_name] = fetch_value(attr_name) unless attribute_changed?(attr_name)
          end

          private
          attr_reader :model, :forced_changes

          def attr_names
            forced_changes.keys
          end

          def attribute_changed?(attr_name)
            forced_changes.include?(attr_name)
          end

          def fetch_value(attr_name)
            model.__send__(attr_name)
          end
        end

        module BackendMethods
          # @!group Backend Accessors
          # @!macro backend_writer
          # @param [Hash] options
          def write(locale, value, options = {})
            locale_accessor = Mobility.normalize_locale_accessor(attribute, locale)
            if model.changed_attributes.has_key?(locale_accessor) && model.changed_attributes[locale_accessor] == value
              mutations_from_mobility.forget_change(locale_accessor)
            elsif read(locale, options.merge(locale: true)) != value
              mutations_from_mobility.force_change(locale_accessor)
            end
            super
          end
          # @!endgroup

          private

          def mutations_from_mobility
            model.send(:mutations_from_mobility)
          end
        end
      end
    end
  end
end
