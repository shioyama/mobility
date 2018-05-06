# frozen-string-literal: true
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/key_value"
require "mobility/sequel/column_changes"
require "mobility/sequel/hash_initializer"
require "mobility/sequel/string_translation"
require "mobility/sequel/text_translation"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::KeyValue} backend for Sequel models.

@note This backend requires the cache to be enabled in order to track
  and store changed translations, since Sequel does not support +build+-type
  methods on associations like ActiveRecord.

=end
    class Sequel::KeyValue
      include Sequel
      include KeyValue
      include Util

      require 'mobility/backends/sequel/key_value/query_methods'

      option_reader :class_name

      # @!group Backend Configuration
      # @option (see Mobility::Backends::KeyValue::ClassMethods#configure)
      # @raise (see Mobility::Backends::KeyValue::ClassMethods#configure)
      # @raise [CacheRequired] if cache is disabled
      def self.configure(options)
        raise CacheRequired, "Cache required for Sequel::KeyValue backend" if options[:cache] == false
        super
        if type = options[:type]
          options[:association_name] ||= :"#{options[:type]}_translations"
          options[:class_name]       ||= Mobility::Sequel.const_get("#{type.capitalize}Translation")
        end
      rescue NameError
        raise ArgumentError, "You must define a Mobility::Sequel::#{type.capitalize}Translation class."
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
            send(association_name).select { |t| attributes.include?(t.key) && Util.blank?(t.value) }.each(&:destroy)
          end
          define_method :after_save do
            super()
            attributes.each { |attribute| public_send(Backend.method_name(attribute)).save_translations }
          end
        end
        include callback_methods

        include DestroyKeyValueTranslations
        include Mobility::Sequel::ColumnChanges.new(attributes)
      end

      setup_query_methods(QueryMethods)

      # Returns translation for a given locale, or initializes one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::Sequel::TextTranslation,Mobility::Sequel::StringTranslation]
      def translation_for(locale, _)
        translation = model.send(association_name).find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= class_name.new(locale: locale, key: attribute)
        translation
      end

      # Saves translation which have been built and which have non-blank values.
      def save_translations
        cache.each_value do |translation|
          next unless present?(translation.value)
          translation.id ? translation.save : model.send("add_#{singularize(association_name)}", translation)
        end
      end

      # Clean up *all* leftover translations of this model, only once.
      module DestroyKeyValueTranslations
        def after_destroy
          super
          [:string, :text].freeze.each do |type|
            Mobility::Sequel.const_get("#{type.capitalize}Translation").
              where(translatable_id: id, translatable_type: self.class.name).destroy
          end
        end
      end

      class CacheRequired < ::StandardError; end

      module Cache
        include KeyValue::Cache

        private

        def translations
          (model.send(association_name) + cache.values).uniq
        end
      end
    end
  end
end
