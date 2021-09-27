# frozen-string-literal: true

module Mobility
  module Plugins
=begin

Plugin to use an original column for a given locale, and otherwise use the backend.

=end
    module ActiveRecord
      module ColumnFallback
        extend Plugin

        requires :column_fallback, include: false

        included_hook do |_, backend_class|
          backend_class.include BackendInstanceMethods
          backend_class.extend BackendClassMethods
        end

        def self.use_column_fallback?(options, locale)
          case column_fallback = options[:column_fallback]
          when TrueClass
            locale == I18n.default_locale
          when Array
            column_fallback.include?(locale)
          when Proc
            column_fallback.call(locale)
          else
            false
          end
        end

        module BackendInstanceMethods
          def read(locale, **)
            if ColumnFallback.use_column_fallback?(options, locale)
              model.read_attribute(attribute)
            else
              super
            end
          end

          def write(locale, value, **)
            if ColumnFallback.use_column_fallback?(options, locale)
              model.send(:write_attribute, attribute, value)
            else
              super
            end
          end
        end

        module BackendClassMethods
          def build_node(attr, locale)
            if ColumnFallback.use_column_fallback?(options, locale)
              model_class.arel_table[attr]
            else
              super
            end
          end
        end
      end
    end

    register_plugin(:active_record_column_fallback, ActiveRecord::ColumnFallback)
  end
end
