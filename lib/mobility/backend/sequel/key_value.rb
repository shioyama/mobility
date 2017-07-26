# frozen-string-literal: true

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::KeyValue} backend for Sequel models.

@note This backend requires the cache to be enabled in order to track
  and store changed translations, since Sequel does not support +build+-type
  methods on associations like ActiveRecord.

=end
    class Sequel::KeyValue
      include Sequel
      include KeyValue

      require 'mobility/backend/sequel/key_value/query_methods'

      # @return [Symbol] name of the association
      attr_reader :association_name

      # @return [Class] translation model class
      attr_reader :class_name

      # @!macro backend_constructor
      # @option options [Symbol] association_name Name of association
      # @option options [Class] class_name Translation model class
      def initialize(model, attribute, **options)
        super
        @association_name = options[:association_name]
        @class_name       = options[:class_name]
      end

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, options)
        translation_for(locale, options).value
      end

      # @!macro backend_writer
      def write(locale, value, options)
        translation_for(locale, options).tap { |t| t.value = value }.value
      end
      # @!endgroup

      # @!group Backend Configuration
      # @option options [Symbol,String] type (:text) Column type to use
      # @option options [Symbol] associaiton_name (:text_translations) Name of association method
      # @option options [Symbol] class_name ({Mobility::Sequel::TextTranslation}) Translation class
      # @raise [CacheRequired] if cache is disabled
      # @raise [ArgumentError] if type is not either :text or :string
      def self.configure(options)
        super
        raise CacheRequired, "Cache required for Sequel::KeyValue backend" if options[:cache] == false
        type = options[:type]
        options[:class_name] ||= Mobility::Sequel.const_get("#{type.capitalize}Translation".freeze)
        options[:class_name] = options[:class_name].constantize if options[:class_name].is_a?(String)
        options[:association_name] ||= :"#{options[:type]}_translations"
        %i[type association_name].each { |key| options[key] = options[key].to_sym }
      end
      # @!endgroup

      setup do |attributes, options|
        association_name   = options[:association_name]
        translations_class = options[:class_name]

        attrs_method_name = :"#{association_name}_attributes"
        association_attributes = (instance_variable_get(:"@#{attrs_method_name}") || []) + attributes
        instance_variable_set(:"@#{attrs_method_name}", association_attributes)

        one_to_many association_name,
          reciprocal:      :translatable,
          key:             :translatable_id,
          reciprocal_type: :one_to_many,
          conditions:      { translatable_type: self.to_s, key: association_attributes },
          adder:           proc { |translation| translation.update(translatable_id: pk, translatable_type: self.class.to_s) },
          remover:         proc { |translation| translation.update(translatable_id: nil, translatable_type: nil) },
          clearer:         proc { send(:"#{association_name}_dataset").update(translatable_id: nil, translatable_type: nil) },
          class:           translations_class

        callback_methods = Module.new do
          define_method :before_save do
            super()
            send(association_name).select { |t| attributes.include?(t.key) && t.value.blank? }.each(&:destroy)
          end
          define_method :after_save do
            super()
            attributes.each { |attribute| mobility_backend_for(attribute).save_translations }
          end
        end
        include callback_methods

        include Mobility::Sequel::ColumnChanges.new(attributes)

        private

        # Clean up *all* leftover translations of this model, only once.
        def self.mobility_key_value_callbacks_module
          @mobility_key_value_destroy_callbacks_module ||= Module.new do
            def after_destroy
              super
              [:string, :text].freeze.each do |type|
                Mobility::Sequel.const_get("#{type.capitalize}Translation".freeze).
                  where(translatable_id: id, translatable_type: self.class.name).destroy
              end
            end
          end
        end unless respond_to?(:mobility_key_value_callbacks_module, true)
        include mobility_key_value_callbacks_module
      end

      setup_query_methods(QueryMethods)

      # Returns translation for a given locale, or initializes one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::Sequel::TextTranslation,Mobility::Sequel::StringTranslation]
      def translation_for(locale, _options = {})
        translation = model.send(association_name).find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= class_name.new(locale: locale, key: attribute)
        translation
      end

      # Saves translation which have been built and which have non-blank values.
      def save_translations
        cache.each_value do |translation|
          next unless translation.value.present?
          translation.id ? translation.save : model.send("add_#{association_name.to_s.singularize}", translation)
        end
      end

      class CacheRequired < ::StandardError; end
    end
  end
end
