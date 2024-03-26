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

In addition, the following ActiveModel attribute handler methods are also
patched to work with translated attributes:
- +attribute_changed?+
- +attribute_previously_changed?+
- +attribute_was+

(When using these methods, you must pass the attribute name along with its
locale suffix, so +title_en+, +title_pt_br+, etc.)

Other methods are also included for ActiveRecord models, see documentation on
the ActiveRecord dirty plugin for more information.

@see http://api.rubyonrails.org/classes/ActiveModel/Dirty.html Rails documentation for Active Model Dirty module

=end
      module Dirty
        extend Plugin

        requires :dirty, include: false

        initialize_hook do
          if options[:dirty]
            define_dirty_methods(names)
            include dirty_handler_methods
          end
        end

        included_hook do |klass, backend_class|
          raise TypeError, "#{name} should include ActiveModel::Dirty to use the active_model plugin" unless active_model_dirty_class?(klass)

          if options[:dirty]
            private_methods = InstanceMethods.instance_methods & klass.private_instance_methods
            klass.include InstanceMethods
            klass.class_eval { private(*private_methods) }

            backend_class.include BackendMethods
          end
        end

        private

        # Overridden in AR::Dirty plugin to define a different HandlerMethods module
        def dirty_handler_methods
          HandlerMethods
        end

        def active_model_dirty_class?(klass)
          klass.ancestors.include?(::ActiveModel::Dirty)
        end

        def define_dirty_methods(attribute_names)
          attribute_names.each do |name|
            dirty_handler_methods.each_pattern(name) do |method_name, attribute_method|
              define_method(method_name) do |*args|
                # for %s_changed?(from:, to:) pattern
                if (kwargs = args.last).is_a?(Hash)
                  mutations_from_mobility.send(attribute_method, Dirty.append_locale(name), *args[0,-1], **kwargs)
                else
                  mutations_from_mobility.send(attribute_method, Dirty.append_locale(name), *args)
                end
              end
            end

            define_method "restore_#{name}!" do
              locale_accessor = Dirty.append_locale(name)
              if mutations_from_mobility.attribute_changed?(locale_accessor)
                __send__("#{name}=", mutations_from_mobility.attribute_was(locale_accessor))
                mutations_from_mobility.restore_attribute!(locale_accessor)
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

        def self.append_locale(attr_name)
          Mobility.normalize_locale_accessor(attr_name)
        end

        # Module builder which mimics dirty method handlers on a given dirty class.
        # Used to mimic ActiveModel::Dirty and ActiveRecord::Dirty, which have
        # similar but slightly different sets of handler methods. Doing it this
        # way with introspection allows us to support basically all AR/AM
        # versions without changes here.
        class HandlerMethodsBuilder < Module
          attr_reader :klass

          # @param [Class] klass Dirty class to mimic
          def initialize(klass)
            @klass = klass
            define_handler_methods
          end

          def each_pattern(attr_name)
            patterns.each do |pattern|
              yield pattern % attr_name, pattern % 'attribute'
            end
          end

          def define_handler_methods
            public_patterns.each do |pattern|
              method_name = pattern % 'attribute'

              kwargs = (pattern == '%s_changed?' || pattern == '%s_previously_changed?') ? ', **kwargs' : ''
              module_eval <<-EOM, __FILE__, __LINE__ + 1
              def #{method_name}(attr_name, *rest#{kwargs})
                if (mutations_from_mobility.attribute_changed?(attr_name) ||
                    mutations_from_mobility.attribute_previously_changed?(attr_name))
                  mutations_from_mobility.send(#{method_name.inspect}, attr_name, *rest#{kwargs})
                else
                  super
                end
              end
              EOM
            end
          end

          # Get method suffixes. Creating an object just to get the list of
          # suffixes is simplest given they change from Rails version to version.
          def patterns
            @patterns ||=
              begin
                # Method name changes in Rails 7.1
                attribute_method_patterns = klass.respond_to?(:attribute_method_patterns) ?
                  klass.attribute_method_patterns :
                  klass.attribute_method_matchers
                attribute_method_patterns.map { |p| "#{p.prefix}%s#{p.suffix}" } - excluded_patterns
              end
          end

          private

          def public_patterns
            @public_patterns ||= patterns.select do |p|
              klass.public_method_defined?(p % 'attribute')
            end
          end

          def excluded_patterns
            ['%s', 'restore_%s!']
          end
        end

        # Module which defines generic handler methods like
        # +attribute_changed?+ that are patched to work with translated
        # attributes.
        HandlerMethods = HandlerMethodsBuilder.new(Class.new { include ::ActiveModel::Dirty })

        module InstanceMethods
          def changed_attributes
            super.merge(mutations_from_mobility.changed_attributes)
          end

          def changes_applied
            super
            mutations_from_mobility.finalize_changes
          end

          def changes
            super.merge(mutations_from_mobility.changes)
          end

          def changed
            # uniq is required for Rails < 6.0
            (super + mutations_from_mobility.changed).uniq
          end

          def changed?
            super || mutations_from_mobility.changed?
          end

          def previous_changes
            super.merge(mutations_from_mobility.previous_changes)
          end

          def clear_changes_information
            @mutations_from_mobility = nil
            super
          end

          def clear_attribute_changes(attr_names)
            attr_names.each { |attr_name| mutations_from_mobility.restore_attribute!(attr_name) }
            super
          end

          private

          def mutations_from_mobility
            @mutations_from_mobility ||= MobilityMutationTracker.new(self)
          end
        end

        # @note Seriously, I really don't want to reproduce all of
        #   ActiveModel::Dirty here, but having fought with upstream changes
        #   many many times I finally decided it's more future-proof to just
        #   re-implement the stuff we need here, to avoid weird breakage.
        #
        #   Although this is somewhat ugly, at least it's explicit and since
        #   it's self-defined (rather than hooking into fickle private methods
        #   in Rails), it won't break all of a sudden. We just need to ensure
        #   that specs are up-to-date with the latest weird dirty method
        #   pattern Rails has decided to support.
        class MobilityMutationTracker
          OPTION_NOT_GIVEN = Object.new

          attr_reader :previous_changes

          def initialize(model)
            @model = model
            @current_changes = {}.with_indifferent_access
            @previous_changes = {}.with_indifferent_access
          end

          def finalize_changes
            @previous_changes = changes
            @current_changes = {}.with_indifferent_access
          end

          def changed
            attr_names.select { |attr_name| attribute_changed?(attr_name) }
          end

          def changed_attributes
            attr_names.each_with_object({}.with_indifferent_access) do |attr_name, result|
              if attribute_changed?(attr_name)
                result[attr_name] = attribute_was(attr_name)
              end
            end
          end

          def changes
            attr_names.each_with_object({}.with_indifferent_access) do |attr_name, result|
              if change = attribute_change(attr_name)
                result.merge!(attr_name => change)
              end
            end
          end

          def changed?
            attr_names.any? { |attr| attribute_changed?(attr) }
          end

          def attribute_change(attr_name)
            if attribute_changed?(attr_name)
              [attribute_was(attr_name), fetch_value(attr_name)]
            end
          end

          def attribute_previous_change(attr_name)
            previous_changes[attr_name]
          end

          def attribute_previously_was(attr_name)
            if attribute_previously_changed?(attr_name)
              # Calling +first+ here fetches the value before change from the
              # hash.
              previous_changes[attr_name].first
            end
          end

          def attribute_changed?(attr_name, from: OPTION_NOT_GIVEN, to: OPTION_NOT_GIVEN)
            current_changes.include?(attr_name) &&
              (OPTION_NOT_GIVEN == from || attribute_was(attr_name) == from) &&
              (OPTION_NOT_GIVEN == to || fetch_value(attr_name) == to)
          end

          def attribute_previously_changed?(attr_name, from: OPTION_NOT_GIVEN, to: OPTION_NOT_GIVEN)
            previous_changes.include?(attr_name) &&
              (OPTION_NOT_GIVEN == from || attribute_previous_change(attr_name).first == from) &&
              (OPTION_NOT_GIVEN == to || attribute_previous_change(attr_name).second == to)
          end

          def attribute_was(attr_name)
            if attribute_changed?(attr_name)
              current_changes[attr_name]
            else
              fetch_value(attr_name)
            end
          end

          def attribute_will_change!(attr_name)
            current_changes[attr_name] = fetch_value(attr_name) unless current_changes.include?(attr_name)
          end

          def restore_attribute!(attr_name)
            current_changes.delete(attr_name)
          end

          # These are for ActiveRecord, but we'll define them here.
          alias_method :saved_change_to_attribute?,     :attribute_previously_changed?
          alias_method :saved_change_to_attribute,      :attribute_previous_change
          alias_method :attribute_before_last_save,     :attribute_previously_was
          alias_method :will_save_change_to_attribute?, :attribute_changed?
          alias_method :attribute_change_to_be_saved,   :attribute_change
          alias_method :attribute_in_database,          :attribute_was

          private
          attr_reader :model, :current_changes

          def attr_names
            current_changes.keys
          end

          def fetch_value(attr_name)
            model.__send__(attr_name)
          end
        end

        module BackendMethods
          # @!group Backend Accessors
          # @!macro backend_writer
          # @param [Hash] options
          def write(locale, value, **options)
            locale_accessor = Mobility.normalize_locale_accessor(attribute, locale)
            if model.changed_attributes.has_key?(locale_accessor) && model.changed_attributes[locale_accessor] == value
              mutations_from_mobility.restore_attribute!(locale_accessor)
            elsif read(locale, **options.merge(locale: true)) != value
              mutations_from_mobility.attribute_will_change!(locale_accessor)
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

    register_plugin(:active_model_dirty, ActiveModel::Dirty)
  end
end
