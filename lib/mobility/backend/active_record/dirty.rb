module Mobility
  module Backend
=begin

Dirty tracking for AR models. See {Mobility::Backend::ActiveModel::Dirty} for
details on usage.

=end
    module ActiveRecord::Dirty
      include ActiveModel::Dirty

      # @param [Class] backend_class Class of backend
      def self.included(backend_class)
        backend_class.extend(ActiveModel::Dirty::ClassMethods)
        backend_class.extend(ClassMethods)
      end

      # Adds hook after {Backend::Setup#setup_model} to patch AR so that it
      # handles changes to translated attributes just like normal attributes.
      module ClassMethods
        # (see Mobility::Backend::Setup#setup_model)
        def setup_model(model_class, attributes, **options)
          super

          method_name_regex = /\A(#{attributes.join('|'.freeze)})_([a-z]{2}(_[a-z]{2})?)(=?|\??)\z/.freeze
          mod = Module.new do
            define_method :has_attribute? do |attr_name|
              super(attr_name) || !!method_name_regex.match(attr_name)
            end
          end

          model_class.class_eval do
            extend mod

            method_name = ::ActiveRecord::VERSION::STRING < '5.1' ? :changes_applied : :changes_internally_applied
            define_method method_name do
              @previously_changed = changes
              super()
            end

            def clear_changes_information
              @previously_changed = ActiveSupport::HashWithIndifferentAccess.new
              super
            end

            def previous_changes
              (@previously_changed ||= ActiveSupport::HashWithIndifferentAccess.new).merge(super)
            end
          end
        end
      end
    end
  end
end
