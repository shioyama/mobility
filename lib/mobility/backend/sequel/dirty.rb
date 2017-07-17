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
      # @param [Hash] options
      def write(locale, value, **options)
        locale_accessor = Mobility.normalize_locale_accessor(attribute, locale).to_sym
        if model.column_changes.has_key?(locale_accessor) && model.initial_values[locale_accessor] == value
          super
          [model.changed_columns, model.initial_values].each { |h| h.delete(locale_accessor) }
        elsif read(locale, options.merge(fallback: false)) != value
          model.will_change_column(locale_accessor)
          super
        end
      end
      # @!endgroup

      class MethodsBuilder < Module
        def initialize(*attribute_names)
          %w[initial_value column_change column_changed? reset_column].each do |method_name|
            define_method method_name do |column|
              if attribute_names.map(&:to_sym).include?(column)
                super(Mobility.normalize_locale_accessor(column).to_sym)
              else
                super(column)
              end
            end
          end
        end

        def included(attributes)
          attributes.model_class.plugin :dirty
        end
      end
    end
  end
end
