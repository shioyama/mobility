module Mobility
  module Backend
    module ActiveModel::Dirty
      def write(locale, value, **options)
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
        def setup_model(model_class, attributes, **options)
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

          restore_methods = Module.new do
            attributes.each do |attribute|
              locale_accessor = "#{attribute}_#{Mobility.locale}"
              define_method "restore_#{attribute}!" do
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
        end
      end
    end
  end
end
