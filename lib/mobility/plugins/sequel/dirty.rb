# frozen-string-literal: true
require "sequel/plugins/dirty"

module Mobility
  module Plugins
=begin

Dirty tracking for Sequel models which use the +Sequel::Plugins::Dirty+ plugin.
Automatically includes dirty plugin in model class when enabled.

@see http://sequel.jeremyevans.net/rdoc-plugins/index.html Sequel dirty plugin

=end
    module Sequel
      module Dirty
        extend Plugin

        requires :dirty, include: false

        initialize_hook do
          # Although we load the plugin in the included callback method, we
          # need to include this module here in advance to ensure that its
          # instance methods are included *before* the ones defined here.
          include ::Sequel::Plugins::Dirty::InstanceMethods
        end

        included_hook do |klass, backend_class|
          if options[:dirty]
            # this just adds Sequel::Plugins::Dirty to @plugins
            klass.plugin :dirty
            define_dirty_methods(names)
            backend_class.include BackendMethods
          end
        end

        private

        def define_dirty_methods(names)
          %w[initial_value column_change column_changed? reset_column].each do |method_name|
            define_method method_name do |column|
              if names.map(&:to_sym).include?(column)
                super(Mobility.normalize_locale_accessor(column).to_sym)
              else
                super(column)
              end
            end
          end
        end

        module BackendMethods
          # @!group Backend Accessors
          # @!macro backend_writer
          # @param [Hash] options
          def write(locale, value, **options)
            locale_accessor = Mobility.normalize_locale_accessor(attribute, locale).to_sym
            if model.column_changes.has_key?(locale_accessor) && model.initial_values[locale_accessor] == value
              super
              [model.changed_columns, model.initial_values].each { |h| h.delete(locale_accessor) }
            elsif read(locale, **options.merge(fallback: false)) != value
              model.will_change_column(locale_accessor)
              super
            end
          end
          # @!endgroup
        end

      end
    end

    register_plugin(:sequel_dirty, Sequel::Dirty)
  end
end
