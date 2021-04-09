# frozen-string-literal: true

module Mobility
=begin

Plugin to use an original column for a given locale, and otherwise use the backend.

=end
  module Plugins
    module Sequel
      module ColumnFallback
        extend Plugin

        requires :column_fallback, include: false

        included_hook do |_, backend_class|
          case (column_fallback = options[:column_fallback])
          when TrueClass
            backend_class.include I18nDefaultLocaleBackend
          when Array, Proc
            backend_class.include BackendModule.new(column_fallback)
          end
        end

        module I18nDefaultLocaleBackend
          def read(locale, **)
            locale == I18n.default_locale ? model[attribute.to_sym] : super
          end

          def write(locale, value, **)
            if locale == I18n.default_locale
              model[attribute.to_sym] = value
            else
              super
            end
          end

          def self.included(base)
            base.extend(ClassMethods)
          end

          module ClassMethods
            def build_op(attr, locale)
              if locale == I18n.default_locale
                ::Sequel::SQL::QualifiedIdentifier.new(model_class.table_name, attr.to_sym)
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
              #{column_fallback}.include?(locale) ? model[attribute.to_sym] : super
            end

            def write(locale, value, **)
              if #{column_fallback}.include?(locale)
                model[attribute.to_sym] = value
              else
                super
              end
            end
            EOM
          end

          def define_proc_accessors
            column_fallback = @column_fallback

            define_method :read do |locale, **options|
              column_fallback.call(locale) ? model[attribute.to_sym] : super(locale, **options)
            end

            define_method :write do |locale, value, **options|
              if column_fallback.call(locale)
                model[attribute.to_sym] = value
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
                def build_op(attr, locale)
                  if #{column_fallback}.include?(locale)
                    ::Sequel::SQL::QualifiedIdentifier.new(model_class.table_name, attr.to_sym)
                  else
                    super
                  end
                end
                EOM
              when Proc
                define_method(:build_op) do |attr, locale|
                  if column_fallback.call(locale)
                    ::Sequel::SQL::QualifiedIdentifier.new(model_class.table_name, attr.to_sym)
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

    register_plugin(:sequel_column_fallback, Sequel::ColumnFallback)
  end
end
