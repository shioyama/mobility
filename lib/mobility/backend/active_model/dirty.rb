module Mobility
  module Backend
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
    module ActiveModel::Dirty
      # @!group Backend Accessors
      # @!macro backend_writer
      # @param [Hash] options
      def write(locale, value, **options)
        locale_accessor = Mobility.normalize_locale_accessor(attribute, locale)
        if model.changed_attributes.has_key?(locale_accessor) && model.changed_attributes[locale_accessor] == value
          model.attributes_changed_by_setter.except!(locale_accessor)
        elsif read(locale, options.merge(fallbacks: false)) != value
          model.send(:attribute_will_change!, locale_accessor)
        end
        super
      end
      # @!endgroup

      # @param [Class] backend_class Class of backend
      def self.included(backend_class)
        backend_class.extend(ClassMethods)
      end

      # Adds hook after {Backend::Setup#setup_model} to add dirty-tracking
      # methods for translated attributes onto model class.
      module ClassMethods
        # (see Mobility::Backend::Setup#setup_model)
        def setup_model(model_class, attributes, **options)
          super
          model_class.class_eval do
            %w[changed? change was will_change! previously_changed? previous_change].each do |suffix|
              attributes.each do |attribute|
                class_eval <<-EOM, __FILE__, __LINE__ + 1
                  def #{attribute}_#{suffix}
                    attribute_#{suffix}(Mobility.normalize_locale_accessor("#{attribute}"))
                  end
                EOM
              end
            end
          end

          restore_methods = Module.new do
            attributes.each do |attribute|
              define_method "restore_#{attribute}!" do
                locale_accessor = Mobility.normalize_locale_accessor(attribute)
                if attribute_changed?(locale_accessor)
                  __send__("#{attribute}=", changed_attributes[locale_accessor])
                end
              end
            end

            define_method :restore_attribute! do |attr|
              if attributes.include?(attr.to_s)
                send("restore_#{attr}!")
              else
                super(attr)
              end
            end
            private :restore_attribute!
          end
          model_class.include restore_methods

          model_class.include(FallthroughAccessors.new(*attributes))
        end
      end
    end
  end
end
