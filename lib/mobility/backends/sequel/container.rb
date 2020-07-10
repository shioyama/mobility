# frozen_string_literal: true
require "mobility/backends/sequel/json"
require "mobility/backends/sequel/jsonb"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Container} backend for Sequel models.

=end
    class Sequel::Container
      include Sequel

      # @!method column_name
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
      #
      # @!group Backend Configuration
      # @option options [Symbol] column_name (:translations) Name of column on which to store translations
      def self.configure(options)
        options[:column_name] ||= :translations
        options[:column_name] = options[:column_name].to_sym
        column_name, db_schema = options[:column_name], options[:model_class].db_schema
        options[:column_type] = db_schema[column_name] && (db_schema[column_name][:db_type]).to_sym
        unless %i[json jsonb].include?(options[:column_type])
          raise InvalidColumnType, "#{options[:column_name]} must be a column of type json or jsonb"
        end
      end
      # @!endgroup
      #
      # @!macro backend_iterator
      def each_locale
        model[column_name].each do |l, _|
          yield l.to_sym unless read(l).nil?
        end
      end

      setup do |attributes, options|
        column_name = options[:column_name]
        before_validation = Module.new do
          define_method :before_validation do
            self[column_name].each do |k, v|
              v.delete_if { |_locale, translation| Util.blank?(translation) }
              self[column_name].delete(k) if v.empty?
            end
            super()
          end
        end
        include before_validation
        include Mobility::Sequel::HashInitializer.new(column_name)

        plugin :defaults_setter
        attributes.each { |attribute| default_values[attribute.to_sym] = {} }
      end

      private

      def model_translations(locale)
        model[column_name][locale.to_s] ||= {}
      end

      def set_attribute_translation(locale, value)
        translations = model[column_name] || {}
        translations[locale.to_s] ||= {}
        # Explicitly mark translations column as changed if value changed,
        # otherwise Sequel will not detect it.
        # TODO: Find a cleaner/easier way to do this.
        if translations[locale.to_s][attribute] != value
          model.instance_variable_set(:@changed_columns, model.changed_columns | [column_name])
        end
        translations[locale.to_s][attribute] = value
      end

      class InvalidColumnType < StandardError; end

      # @param [Symbol] name Attribute name
      # @param [Symbol] locale Locale
      # @return [Mobility::Backends::Sequel::Container::JSONOp,Mobility::Backends::Sequel::Container::JSONBOp]
      def self.build_op(attr, locale)
        klass = const_get("#{options[:column_type].upcase}Op")
        klass.new(klass.new(column_name.to_sym)[locale.to_s]).get_text(attr)
      end

      class JSONOp < ::Sequel::Postgres::JSONOp; end

      class JSONBOp < Jsonb::JSONBOp
        def to_question
          left = @value.args[0].value
          JSONBOp === left ? ::Sequel.&(super, left.to_question) : super
        end
      end
    end

    register_backend(:sequel_container, Sequel::Container)
  end
end
