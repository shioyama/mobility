module Mobility
  module Backend
    module Dirty
      def read(locale, options = {})
        super.tap do |value|
          original_values[locale] = value.to_s.presence unless original_values.has_key?(locale)
        end
      end

      def write(locale, value, options = {})
        read(locale) unless original_values.has_key?(locale)
        if value == original_values[locale]
          model.original_changed_attributes.except!("#{attribute}_#{locale}")
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
            include ActiveModel::Dirty
            include BackendResetter.new(:clear_original_values, attributes)
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

      def clear_original_values
        @original_values = {}
      end

      private

      def original_values
        @original_values ||= {}
      end
    end
  end
end
