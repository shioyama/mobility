module Mobility
  module Backend
    class Table
      include Base
      attr_accessor :association_name

      def initialize(model, attribute, options = {})
        super
        @association_name = options[:association_name]
      end

      def read(locale, options = {})
        Stash.new(translation_for(locale))
      end

      def write(locale, value, options = {})
        Stash.new(translation_for(locale).tap { |t| t.value = value })
      end

      def self.configure!(options)
        options[:association_name] ||= :mobility_translations
        options[:class_name]       ||= Mobility::ActiveRecord::Translation
      end

      setup do |attributes, options|
        association_name   = options[:association_name]
        translations_class = options[:class_name]
        translations_class = translations_class.classify if translations_class.is_a?(String)
        has_many association_name, as:         :translatable,
                                   class_name: translations_class,
                                   dependent:  :destroy,
                                   inverse_of: :translatable,
                                   autosave:   true
        before_validation do
          send(association_name).select { |t| t.value.blank? }.each(&:destroy)
        end

        private association_name, "#{association_name}="
      end

      private

      def translations
        model.send(association_name)
      end

      def translation_for(locale)
        translation = translations.find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= translations.build(locale: locale, key: attribute)
        translation
      end

      class Stash
        def initialize(translation)
          @translation = translation
        end

        def to_s
          @translation.value
        end

        def write(value)
          @translation.value = value
        end
      end
    end
  end
end
