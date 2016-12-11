require "sequel/plugins/dirty"

module Mobility
  module Backend
    module Sequel::Dirty
      def write(locale, value, **options)
        model.send(:will_change_column, "#{attribute}_#{locale}".to_sym)
        super
      end

      def self.included(backend_class)
        backend_class.extend(ClassMethods)
      end

      module ClassMethods
        def setup_model(model_class, attributes, **options)
          super
          model_class.class_eval do
            plugin :dirty
            %w[initial_value column_change column_changed? reset_column].each do |method_name|
              define_method method_name do |column|
                if attributes.map(&:to_sym).include?(column)
                  super("#{column}_#{Mobility.locale}".to_sym)
                else
                  super(column)
                end
              end
            end
          end
        end
      end
    end
  end
end
