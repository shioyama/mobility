# frozen-string-literal: true

module Mobility
  module Backend
=begin

Dirty tracking for AR models. See {Mobility::Backend::ActiveModel::Dirty} for
details on usage.

=end
    module ActiveRecord::Dirty
      include ActiveModel::Dirty

      # Builds module which patches a few AR methods to handle changes to
      # translated attributes just like normal attributes.
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

        # Overrides +ActiveRecord::AttributeMethods::ClassMethods#has_attribute+ to treat fallthrough attribute methods
        # just like "real" attribute methods.
        #
        # @note Patching +has_attribute?+ is necessary as of AR 5.1 due to this commit[https://github.com/rails/rails/commit/4fed08fa787a316fa51f14baca9eae11913f5050].
        #   (I have voiced my opposition to this change here[https://github.com/rails/rails/pull/27963#issuecomment-310092787]).
        # @param [Attributes] attributes
        def included(model_class)
          names = @attribute_names
          method_name_regex = /\A(#{names.join('|'.freeze)})_([a-z]{2}(_[a-z]{2})?)(=?|\??)\z/.freeze
          has_attribute = Module.new do
            define_method :has_attribute? do |attr_name|
              super(attr_name) || !!method_name_regex.match(attr_name)
            end
          end
          model_class.extend has_attribute
        end
      end
    end
  end
end
