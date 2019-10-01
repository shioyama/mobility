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

In addition, the private method +restore_attribute!+ will also restore the
value of the translated attribute if passed to it.

@see http://api.rubyonrails.org/classes/ActiveModel/Dirty.html Rails documentation for Active Model Dirty module

=end
      module Dirty
        # Builds module which adds suffix/prefix methods for translated
        # attributes so they act like normal dirty-tracked attributes.
        class MethodsBuilder < Module
          def initialize(*attribute_names)
            attribute_names.each do |name|
              method_suffixes.each do |suffix|
                define_method "#{name}#{suffix}" do
                  __send__("attribute#{suffix}", Mobility.normalize_locale_accessor(name))
                end
              end

              define_method "restore_#{name}!" do
                locale_accessor = Mobility.normalize_locale_accessor(name)
                if attribute_changed?(locale_accessor)
                  __send__("#{name}=", changed_attributes[locale_accessor])
                end
              end
            end

            define_method :restore_attribute! do |attr|
              attribute_names.include?(attr.to_s) ? send("restore_#{attr}!") : super(attr)
            end
            private :restore_attribute!
          end

          def included(model_class)
            model_class.include ChangedAttributes
          end

          private

          # Get method suffixes. Creating an object just to get the list of
          # suffixes is not very efficient, but the most reliable way given that
          # they change from Rails version to version.
          def method_suffixes
            @method_suffixes ||=
              Class.new do
                include ::ActiveModel::Dirty
              end.attribute_method_matchers.map(&:suffix).select { |m| m =~ /\A_/ }
          end

          # Tracks which translated attributes have been changed, separate from
          # the default tracking of changes in ActiveModel/ActiveRecord Dirty.
          # This is required in order for the Mobility ActiveRecord Dirty
          # plugin to correctly read the value of locale accessors like
          # +title_en+ in dirty tracking.
          module ChangedAttributes
            private

            def mobility_changed_attributes
              @mobility_changed_attributes ||= Set.new
            end
          end
        end

        module BackendMethods
          # @!group Backend Accessors
          # @!macro backend_writer
          # @param [Hash] options
          def write(locale, value, options = {})
            locale_accessor = Mobility.normalize_locale_accessor(attribute, locale)
            if model.changed_attributes.has_key?(locale_accessor) && model.changed_attributes[locale_accessor] == value
              model.send(:attributes_changed_by_setter).except!(locale_accessor)
            else
              _, backend_value = read(locale, options.merge(locale: true))
              if backend_value != value
                model.send(:mobility_changed_attributes) << locale_accessor
                model.send(:attribute_will_change!, locale_accessor)
              end
            end
            super
          end
          # @!endgroup
        end
      end
    end
  end
end
