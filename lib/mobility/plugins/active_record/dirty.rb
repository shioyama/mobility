# frozen-string-literal: true
require "mobility/plugins/active_model/dirty"

module Mobility
  module Plugins
=begin

Dirty tracking for AR models. See {Mobility::Plugins::ActiveModel::Dirty} for
details on usage.

In addition to methods added by {Mobility::Plugins::ActiveModel::Diryt}, the
AR::Dirty plugin adds support for the following persistence-specific methods
(for a model with a translated attribute +title+):
- +saved_changes+
- +saved_change_to_title?+
- +saved_change_to_title+
- +title_before_last_save+
- +will_save_change_to_title?+
- +title_change_to_be_saved+
- +title_in_database+

=end
    module ActiveRecord
      module Dirty
        include ActiveModel::Dirty

        # Builds module which patches a few AR methods to handle changes to
        # translated attributes just like normal attributes.
        class MethodsBuilder < ActiveModel::Dirty::MethodsBuilder
          def initialize(*attribute_names)
            super
            @attribute_names = attribute_names
            define_method_overrides
            define_attribute_methods if ::ActiveRecord::VERSION::STRING >= '5.1'
          end

          # Overrides +ActiveRecord::AttributeMethods::ClassMethods#has_attribute+ and
          # +ActiveModel::AttributeMethods#_read_attribute+ to treat
          # fallthrough attribute methods just like "real" attribute methods.
          #
          # @note Patching +has_attribute?+ is necessary as of AR 5.1 due to this commit[https://github.com/rails/rails/commit/4fed08fa787a316fa51f14baca9eae11913f5050].
          #   (I have voiced my opposition to this change here[https://github.com/rails/rails/pull/27963#issuecomment-310092787]).
          # @param [Attributes] attributes
          def included(model_class)
            super
            names = @attribute_names
            method_name_regex = /\A(#{names.join('|'.freeze)})_([a-z]{2}(_[a-z]{2})?)(=?|\??)\z/.freeze
            has_attribute = Module.new do
              define_method :has_attribute? do |attr_name|
                super(attr_name) || !!method_name_regex.match(attr_name)
              end
            end
            model_class.extend has_attribute
            model_class.include ReadAttribute if ::ActiveRecord::VERSION::STRING >= '5.2'
          end

          private

          def define_method_overrides
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

          # For AR >= 5.1 only
          def define_attribute_methods
            define_method :saved_changes do
              (@previously_changed ||= ActiveSupport::HashWithIndifferentAccess.new).merge(super())
            end

            @attribute_names.each do |name|
              define_method :"saved_change_to_#{name}?" do
                previous_changes.include?(Mobility.normalize_locale_accessor(name))
              end

              define_method :"saved_change_to_#{name}" do
                previous_changes[Mobility.normalize_locale_accessor(name)]
              end

              define_method :"#{name}_before_last_save" do
                previous_changes[Mobility.normalize_locale_accessor(name)].first
              end

              alias_method :"will_save_change_to_#{name}?", :"#{name}_changed?"
              alias_method :"#{name}_change_to_be_saved", :"#{name}_change"
              alias_method :"#{name}_in_database", :"#{name}_was"
            end
          end

          # Overrides _read_attribute to correctly dispatch reads on translated
          # attributes to their respective setters, rather than to
          # +@attributes+, which would otherwise return +nil+.
          #
          # For background on why this is necessary, see:
          # https://github.com/shioyama/mobility/issues/115
          module ReadAttribute
            # @note We first check if attributes has the key +attr+ to avoid
            #   doing any extra work in case this is a "normal"
            #   (non-translated) attribute.
            def _read_attribute(attr, *args)
              if @attributes.key?(attr)
                super
              else
                mobility_changed_attributes.include?(attr) ? __send__(attr) : super
              end
            end
            private :_read_attribute
          end
        end
      end
    end
  end
end
