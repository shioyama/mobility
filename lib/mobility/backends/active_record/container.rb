# frozen_string_literal: true
require "mobility/backends/active_record"
require "mobility/backends/container"
require "mobility/plugins/arel/nodes/pg_ops"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Container} backend for ActiveRecord models.

=end
    class ActiveRecord::Container
      include ActiveRecord
      include Container

      # @!group Backend Accessors
      #
      # @note Translation may be a string, integer, boolean, hash or array
      #   since value is stored on a JSON hash.
      # @param [Symbol] locale Locale to read
      # @param [Hash] options
      # @return [String,Integer,Boolean] Value of translation
      def read(locale, _ = nil)
        locale_translations = model_translations(locale)

        return unless locale_translations

        locale_translations[attribute.to_s]
      end

      # @note Translation may be a string, integer, boolean, hash or array
      #   since value is stored on a JSON hash.
      # @param [Symbol] locale Locale to write
      # @param [String,Integer,Boolean] value Value to write
      # @param [Hash] options
      # @return [String,Integer,Boolean] Updated value
      def write(locale, value, _ = nil)
        set_attribute_translation(locale, value)
        read(locale)
      end
      # @!endgroup

      class << self
        # @!group Backend Configuration
        # @option options [Symbol] column_name (:translations) Name of column on which to store translations
        # @raise [InvalidColumnType] if the type of the container column is not json or jsonb
        def configure(options)
          options[:column_name] = options[:column_name]&.to_sym || :translations
        end
        # @!endgroup

        # @param [String] attr Attribute name
        # @param [Symbol] locale Locale
        # @return [Mobility::Plugins::Arel::Nodes::Json,Mobility::Arel::Nodes::Jsonb] Arel
        #   node for attribute on json or jsonb column
        def build_node(attr, locale)
          column = model_class.arel_table[column_name]
          case column_type
          when :json
            Plugins::Arel::Nodes::JsonContainer.new(column, build_quoted(locale), build_quoted(attr))
          when :jsonb
            Plugins::Arel::Nodes::JsonbContainer.new(column, build_quoted(locale), build_quoted(attr))
          end
        end

        def column_type
          @column_type ||= get_column_type
        end

        private

        def get_column_type
          model_class.type_for_attribute(options[:column_name].to_s).try(:type).tap do |type|
            unless %i[json jsonb].include? type
              raise InvalidColumnType, "#{options[:column_name]} must be a column of type json or jsonb"
            end
          end
        end
      end

      # @!macro backend_iterator
      def each_locale
        model[column_name].each_key do |l|
          yield l.to_sym
        end
      end

      setup do |_attributes, options|
        # Fix for duping depth-2 jsonb column in AR < 5.0
        if ::ActiveRecord::VERSION::STRING < '5.0'
          column_name = options[:column_name]
          module_name = "MobilityArContainer#{column_name.to_s.camelcase}"
          unless const_defined?(module_name)
            dupable = Module.new do
              class_eval <<-EOM, __FILE__, __LINE__ + 1
                def initialize_dup(source)
                  super
                  self.#{column_name} = source.#{column_name}.deep_dup
                end
              EOM
            end
            include const_set(module_name, dupable)
          end
        end
      end

      private

      def model_translations(locale)
        model[column_name][locale.to_s]
      end

      def set_attribute_translation(locale, value)
        locale_translations = model_translations(locale)

        if locale_translations
          if value.nil?
            locale_translations.delete(attribute.to_s)

            # delete empty locale hash if last attribute was just deleted
            model[column_name].delete(locale.to_s) if locale_translations.empty?
          else
            locale_translations[attribute.to_s] = value
          end
        elsif !value.nil?
          model[column_name][locale.to_s] = { attribute.to_s => value }
        end
      end

      class InvalidColumnType < StandardError; end
    end

    register_backend(:active_record_container, ActiveRecord::Container)
  end
end
