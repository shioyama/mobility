module Mobility
  module Backend
=begin

Dirty tracking for AR models. See {Mobility::Backend::ActiveModel::Dirty} for
details on usage.

=end
    module ActiveRecord::Dirty
      include ActiveModel::Dirty

      # Adds hook after {Backend::Setup#setup_model} to patch AR so that it
      # handles changes to translated attributes just like normal attributes.
      class MethodsBuilder < ActiveModel::Dirty::MethodsBuilder
        def initialize(*attribute_names)
          super
          @attribute_names = attribute_names

          changes_applied_method = ::ActiveRecord::VERSION::STRING < '5.1' ? :changes_applied : :changes_internally_applied
          define_method changes_applied_method do
            @previously_changed = changes
            super()
          end

          define_method :clear_changes_information do
            @previously_changed = ActiveSupport::HashWithIndifferentAccess.new
            super()
          end

          define_method :previous_changes do
            (@previously_changed ||= ActiveSupport::HashWithIndifferentAccess.new).merge(super())
          end
        end

        def included(attributes)
          names = @attribute_names
          method_name_regex = /\A(#{names.join('|'.freeze)})_([a-z]{2}(_[a-z]{2})?)(=?|\??)\z/.freeze
          has_attribute = Module.new do
            define_method :has_attribute? do |attr_name|
              super(attr_name) || !!method_name_regex.match(attr_name)
            end
          end
          attributes.model_class.extend has_attribute
        end
      end
    end
  end
end
