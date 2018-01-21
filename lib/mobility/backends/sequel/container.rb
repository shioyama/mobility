module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Container} backend for Sequel models.

=end
    class Sequel::Container
      include Sequel

      require 'mobility/backends/sequel/container/query_methods'

      # @return [Symbol] name of container column
      attr_reader :column_name

      # @!macro backend_constructor
      # @option options [Symbol] column_name Name of container column
      def initialize(model, attribute, options = {})
        super
        @column_name = options[:column_name]
      end

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

      setup_query_methods(QueryMethods)

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
    end
  end
end
