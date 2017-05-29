# frozen-string-literal: true

module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::KeyValue} backend for ActiveRecord models.

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

      require 'mobility/backend/active_record/key_value/query_methods'

      # @return [Symbol] Name of the association
      attr_reader :association_name

      # @!macro backend_constructor
      # @option options [Symbol] association_name Name of association
      def initialize(model, attribute, **options)
        super
        @association_name = options[:association_name]
      end

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, **_)
        translation_for(locale).value
      end

      # @!macro backend_reader
      def write(locale, value, **_)
        translation_for(locale).tap { |t| t.value = value }.value
      end
      # @!endgroup

      # @!group Backend Configuration
      # @option options [Symbol] type (:text) Column type to use
      # @option options [Symbol] association_name (:mobility_text_translations) Name of association method
      # @option options [String,Class] class_name ({Mobility::ActiveRecord::TextTranslation}) Translation class
      # @raise [ArgumentError] if type is not either :text or :string
      def self.configure(options)
        super
        type = options[:type]
        options[:class_name] ||= Mobility::ActiveRecord.const_get("#{type.capitalize}Translation".freeze)
        options[:class_name] = options[:class_name].constantize if options[:class_name].is_a?(String)
        options[:association_name] ||= options[:class_name].table_name.to_sym
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

      # @!group Cache Methods
      # @return [KeyValue::TranslationsCache]
      def new_cache
        KeyValue::TranslationsCache.new(self)
      end

      # @return [Boolean]
      def write_to_cache?
        true
      end
      # @!endgroup

      # Returns translation for a given locale, or builds one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::ActiveRecord::TextTranslation,Mobility::ActiveRecord::StringTranslation]
      def translation_for(locale)
        translation = translations.find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= translations.build(locale: locale, key: attribute)
        translation
      end

      def translations
        model.send(association_name)
      end
    end
  end
end
