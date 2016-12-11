module Mobility
  module Backend
    module ActiveModel::Dirty
      def write(locale, value, options = {})
        locale_accessor = "#{attribute}_#{locale}"
        if model.changed_attributes.has_key?(locale_accessor) && model.changed_attributes[locale_accessor] == value
          model.attributes_changed_by_setter.except!(locale_accessor)
        else
          model.send(:attribute_will_change!, "#{attribute}_#{locale}")
        end
        super
      end

      def self.included(backend_class)
        backend_class.extend(ClassMethods)
      end

      module ClassMethods
        def setup_model(model_class, attributes, options = {})
          super
          model_class.class_eval do
            %w[changed? change was will_change! previously_changed? previous_change].each do |suffix|
              attributes.each do |attribute|
                class_eval <<-EOM, __FILE__, __LINE__ + 1
                  def #{attribute}_#{suffix}
                    attribute_#{suffix}("#{attribute}_#\{Mobility.locale\}")
                  end
                EOM
              end
            end
          end
        end
      end
    end
  end
end
