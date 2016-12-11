begin
  require "sequel_polymorphic"
rescue LoadError
  raise LoadError, "You must include sequel_polymorphic in your Gemfile to use the Table backend with Sequel"
end

module Mobility
  module Backend
    class Sequel::Table
      include Base
      attr_reader :association_name, :class_name

      def initialize(model, attribute, **options)
        super
        @association_name = options[:association_name]
        @class_name       = options[:class_name]
      end

      def read(locale, **options)
        translation_for(locale)
      end

      def write(locale, value, **options)
        translation_for(locale).tap { |t| t.value = value }
      end

      def save_stashes
        cache.each_value do |translation|
          next unless translation.value.present?
          translation.id ? translation.save : model.send("add_#{association_name.to_s.singularize}", translation)
        end
      end

      def self.configure!(options)
        raise CacheRequired, "Cache required for Sequel::Table backend" if options[:cache] == false
        options[:association_name] ||= :mobility_translations
        options[:class_name]       ||= Mobility::Sequel::Translation
        options[:class_name] = options[:class_name].constantize if options[:class_name].is_a?(String)
      end

      setup do |attributes, options|
        association_name   = options[:association_name]
        translations_class = options[:class_name]
        plugin :polymorphic
        one_to_many association_name, as: :translatable, class: translations_class, read_only: true
        plugin :association_dependencies, association_name => :destroy

        mod = Module.new do
          define_method :before_save do
            super()
            send(association_name).select { |t| t.value.blank? }.each(&:destroy)
          end
          define_method :after_save do
            super()
            attributes.each { |attribute| mobility_backend_for(attribute).save_stashes }
          end
        end
        include mod

        table_name = self.table_name
        dataset_module do
          define_method :with_translations do
            join(association_name, translatable_id: :id).select_all(table_name).where(locale: Mobility.locale.to_s)
          end
        end

        attributes.each do |attribute|
          class_eval <<-EOM, __FILE__, __LINE__ + 1
            def self.first_by_#{attribute}(value)
              with_translations.where(key: "#{attribute}", value: value).first
            end
          EOM
        end
      end

      class CacheRequired < ::StandardError; end

      private

      def translation_for(locale)
        translation = model.send(association_name).find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= class_name.new(locale: locale, key: attribute)
        translation
      end
    end
  end
end
