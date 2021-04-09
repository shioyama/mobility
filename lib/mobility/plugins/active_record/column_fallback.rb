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
          case (column_fallback = options[:column_fallback])
          when TrueClass
            backend_class.include I18nDefaultLocaleBackend
          when Array, Proc
            backend_class.include BackendModule.new(column_fallback)
          else
            raise ArgumentError, "column_fallback value must be a boolean, an array of locales or a proc"
          end
        end

        module I18nDefaultLocaleBackend
          def read(locale, **)
            locale == I18n.default_locale ? model.read_attribute(attribute) : super
          end

          def write(locale, value, **)
            locale == I18n.default_locale ? model.send(:write_attribute, attribute, value) : super
          end

          def self.included(base)
            base.extend(ClassMethods)
          end

          module ClassMethods
            def build_node(attr, locale)
              if locale == I18n.default_locale
                model_class.arel_table[attr]
              else
                super
              end
            end
          end
        end

        class BackendModule < Module
          def initialize(column_fallback)
            case (@column_fallback = column_fallback)
            when Array
              define_array_accessors
            when Proc
              define_proc_accessors
            end
          end

          def included(base)
            base.extend(ClassMethods.new(@column_fallback))
          end

          private

          def define_array_accessors
            column_fallback = @column_fallback

            module_eval <<-EOM, __FILE__, __LINE__ + 1
            def read(locale, **)
              if #{column_fallback}.include?(locale)
                model.read_attribute(attribute)
              else
                super
              end
            end

            def write(locale, value, **)
              if #{column_fallback}.include?(locale)
                model.send(:write_attribute, attribute, value)
              else
                super
              end
            end
            EOM
          end

          def define_proc_accessors
            column_fallback = @column_fallback

            define_method :read do |locale, **options|
              if column_fallback.call(locale)
                model.read_attribute(attribute)
              else
                super(locale, **options)
              end
            end

            define_method :write do |locale, value, **options|
              if column_fallback.call(locale)
                model.send(:write_attribute, attribute, value)
              else
                super(locale, value, **options)
              end
            end
          end

          class ClassMethods < Module
            def initialize(column_fallback)
              case column_fallback
              when Array
                module_eval <<-EOM, __FILE__, __LINE__ + 1
                def build_node(attr, locale)
                  if #{column_fallback}.include?(locale)
                    model_class.arel_table[attr]
                  else
                    super
                  end
                end
                EOM
              when Proc
                define_method(:build_node) do |attr, locale|
                  if column_fallback.call(locale)
                    model_class.arel_table[attr]
                  else
                    super(attr, locale)
                  end
                end
              end
            end
          end
        end
      end
    end

    register_plugin(:active_record_column_fallback, ActiveRecord::ColumnFallback)
  end
end
