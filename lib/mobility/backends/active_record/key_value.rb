# frozen-string-literal: true
require "mobility/backends/active_record"
require "mobility/backends/key_value"
require "mobility/active_record/string_translation"
require "mobility/active_record/text_translation"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::KeyValue} backend for ActiveRecord models.

@example
  class Post < ActiveRecord::Base
    translates :title, backend: :key_value, association_name: :translations, type: :string
  end

  post = Post.create(title: "foo")
  post.translations
  #=> #<ActiveRecord::Associations::CollectionProxy ... >
  post.translations.first.value
  #=> "foo"
  post.translations.first.class
  #=> Mobility::ActiveRercord::StringTranslation

=end
    class ActiveRecord::KeyValue
      include ActiveRecord
      include KeyValue

      require 'mobility/backends/active_record/key_value/query_methods'

      # @!group Backend Configuration
      # @option options [Symbol] type (:text) Column type to use
      # @option options [Symbol] association_name (:text_translations) Name of association method
      # @option options [String,Class] class_name ({Mobility::ActiveRecord::TextTranslation}) Translation class
      # @raise [ArgumentError] if type is not either :text or :string
      def self.configure(options)
        super
        type = options[:type]
        options[:class_name] ||= Mobility::ActiveRecord.const_get("#{type.capitalize}Translation".freeze)
        options[:class_name] = options[:class_name].constantize if options[:class_name].is_a?(String)
        options[:association_name] ||= :"#{options[:type]}_translations"
        %i[type association_name].each { |key| options[key] = options[key].to_sym }
      end
      # @!endgroup

      setup do |attributes, options|
        association_name   = options[:association_name]
        translations_class = options[:class_name]

        # Track all attributes for this association, so that we can limit the scope
        # of keys for the association to only these attributes. We need to track the
        # attributes assigned to the association in case this setup code is called
        # multiple times, so we don't "forget" earlier attributes.
        #
        attrs_method_name = :"__#{association_name}_attributes"
        association_attributes = (instance_variable_get(:"@#{attrs_method_name}") || []) + attributes
        instance_variable_set(:"@#{attrs_method_name}", association_attributes)

        has_many association_name, ->{ where key: association_attributes },
          as: :translatable,
          class_name: translations_class.name,
          inverse_of: :translatable,
          autosave:   true
        before_save do
          send(association_name).select { |t| t.value.blank? }.each do |translation|
            send(association_name).destroy(translation)
          end
        end
        after_destroy :mobility_destroy_key_value_translations

        module_name = "MobilityArKeyValue#{association_name.to_s.camelcase}"
        unless const_defined?(module_name)
          callback_methods = Module.new do
            define_method :initialize_dup do |source|
              super(source)
              self.send("#{association_name}=", source.send(association_name).map(&:dup))
              # Set inverse on associations
              send(association_name).each { |translation| translation.translatable = self }
            end
          end
          include const_set(module_name, callback_methods)
        end

        private

        # Clean up *all* leftover translations of this model, only once.
        def mobility_destroy_key_value_translations
          [:string, :text].freeze.each do |type|
            Mobility::ActiveRecord.const_get("#{type.capitalize}Translation".freeze).
              where(translatable: self).destroy_all
          end
        end unless private_instance_methods(false).include?(:mobility_destroy_key_value_translations)
      end

      setup_query_methods(QueryMethods)

      # Returns translation for a given locale, or builds one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::ActiveRecord::TextTranslation,Mobility::ActiveRecord::StringTranslation]
      def translation_for(locale, _options = {})
        translation = translations.find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= translations.build(locale: locale, key: attribute)
        translation
      end
    end
  end
end
