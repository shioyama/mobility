# frozen_string_literal: true
require "mobility/backends/active_record"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Container} backend for ActiveRecord models.

=end
    class ActiveRecord::Container
      include ActiveRecord

      require 'mobility/backends/active_record/container/json_query_methods'
      require 'mobility/backends/active_record/container/jsonb_query_methods'

      # @!method column_name
      #   Returns name of json or jsonb column used to store translations
      #   @return [Symbol] (:translations) Name of translations column
      option_reader :column_name

      # @!group Backend Accessors
      #
      # @note Translation may be a string, integer, boolean, hash or array
      #   since value is stored on a JSON hash.
      # @param [Symbol] locale Locale to read
      # @param [Hash] options
      # @return [String,Integer,Boolean] Value of translation
      def read(locale, _ = nil)
        model_translations(locale)[attribute]
      end

      # @note Translation may be a string, integer, boolean, hash or array
      #   since value is stored on a JSON hash.
      # @param [Symbol] locale Locale to write
      # @param [String,Integer,Boolean] value Value to write
      # @param [Hash] options
      # @return [String,Integer,Boolean] Updated value
      def write(locale, value, _ = nil)
        set_attribute_translation(locale, value)
        model_translations(locale)[attribute]
      end
      # @!endgroup

      # @!group Backend Configuration
      # @option options [Symbol] column_name (:translations) Name of column on which to store translations
      # @raise [InvalidColumnType] if the type of the container column is not json or jsonb
      def self.configure(options)
        options[:column_name] ||= :translations
        options[:column_name] = options[:column_name].to_sym
        options[:column_type] = options[:model_class].type_for_attribute(options[:column_name].to_s).try(:type)
        unless %i[json jsonb].include?(options[:column_type])
          raise InvalidColumnType, "#{options[:column_name]} must be a column of type json or jsonb"
        end
      end
      # @!endgroup

      # @!macro backend_iterator
      def each_locale
        model[column_name].each do |l, v|
          yield l.to_sym if v.present?
        end
      end

      backend_class = self

      setup do |attributes, options|
        store options[:column_name], coder: Coder

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

        query_methods = backend_class.const_get("#{options[:column_type].capitalize}QueryMethods")
        extend(Module.new do
          define_method ::Mobility.query_method do
            super().extending(query_methods.new(attributes, options))
          end
        end)
      end

      private

      def model_translations(locale)
        model[column_name][locale] ||= {}
      end

      def set_attribute_translation(locale, value)
        translations = model[column_name] || {}
        translations[locale.to_s] ||= {}
        translations[locale.to_s][attribute] = value
        model[column_name] = translations
      end

      class Coder
        def self.dump(obj)
          if obj.is_a? Hash
            obj.inject({}) do |translations, (locale, value)|
              value.each do |k, v|
                (translations[locale] ||= {})[k] = v if v.present?
              end
              translations
            end
          else
            raise ArgumentError, "Attribute is supposed to be a Hash, but was a #{obj.class}. -- #{obj.inspect}"
          end
        end

        def self.load(obj)
          obj
        end
      end

      class InvalidColumnType < StandardError; end
    end
  end
end
