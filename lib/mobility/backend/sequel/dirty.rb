module Mobility
  module Backend
=begin

Dirty tracking for Sequel models which use the +Sequel::Plugins::Dirty+ plugin.
Automatically includes dirty plugin in model class when enabled.

@see http://sequel.jeremyevans.net/rdoc-plugins/index.html Sequel dirty plugin

=end
    module Sequel::Dirty
      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, **options)
        locale_accessor = "#{attribute}_#{locale}".to_sym
        if model.column_changes.has_key?(locale_accessor) && model.initial_values[locale_accessor] == value
          super
          [model.changed_columns, model.initial_values].each { |h| h.delete(locale_accessor) }
        elsif read(locale, **options) != value
          model.will_change_column("#{attribute}_#{locale}".to_sym)
          super
        end
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
        def setup_model(model_class, attributes, **)
          super
          model_class.plugin :dirty
          model_class.class_eval do
            mod = Module.new do
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
            include mod
          end
        end
      end
    end
  end
end
