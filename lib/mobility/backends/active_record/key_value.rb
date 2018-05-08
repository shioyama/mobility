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
    extend Mobility
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

      class << self
        # @!group Backend Configuration
        # @option (see Mobility::Backends::KeyValue::ClassMethods#configure)
        # @raise (see Mobility::Backends::KeyValue::ClassMethods#configure)
        def configure(options)
          super
          if type = options[:type]
            options[:association_name] ||= :"#{options[:type]}_translations"
            options[:class_name]       ||= Mobility::ActiveRecord.const_get("#{type.capitalize}Translation")
          end
        rescue NameError
          raise ArgumentError, "You must define a Mobility::ActiveRecord::#{type.capitalize}Translation class."
        end
        # @!endgroup

        # @param [String] attr Attribute name
        # @param [Symbol] _locale Locale
        # @return [Arel::Attributes::Attribute] Arel attribute for aliased
        #   translation table value column
        def build_node(attr, _locale)
          class_name.arel_table.alias("#{attr}_#{association_name}")[:value]
        end

        # @param [ActiveRecord::Relation] relation Relation to scope
        # @param [Hash] opts Hash of options for query
        # @param [Symbol] locale Locale
        # @option [Boolean] invert
        def add_translations(relation, opts, locale, invert: false)
          i18n_keys, i18n_nulls = partition_opts(opts)

          relation = join_translations(relation, i18n_keys, locale)
          join_translations(relation, i18n_nulls, locale, outer_join: !invert)
        end

        private

        def partition_opts(opts)
          opts.keys.partition { |key| opts[key] && [*opts[key]].all? }
        end

        def join_translations(relation, keys, locale, outer_join: false)
          keys.inject(relation) do |r, key|
            t = class_name.arel_table.alias("#{key}_#{association_name}")
            m = model_class.arel_table
            join_type = outer_join ? ::Arel::Nodes::OuterJoin : ::Arel::Nodes::InnerJoin
            r.joins(m.join(t, join_type).
                    on(t[:key].eq(key).
                       and(t[:locale].eq(locale).
                           and(t[:translatable_type].eq(model_class.base_class.name).
                               and(t[:translatable_id].eq(m[:id]))))).join_sources)
          end
        end
      end

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

        include DestroyKeyValueTranslations
      end

      # Returns translation for a given locale, or builds one if none is present.
      # @param [Symbol] locale
      # @return [Mobility::ActiveRecord::TextTranslation,Mobility::ActiveRecord::StringTranslation]
      def translation_for(locale, _options = {})
        translation = translations.find { |t| t.key == attribute && t.locale == locale.to_s }
        translation ||= translations.build(locale: locale, key: attribute)
        translation
      end

      module DestroyKeyValueTranslations
        def self.included(model_class)
          model_class.after_destroy do
            [:string, :text].each do |type|
              Mobility::ActiveRecord.const_get("#{type.capitalize}Translation").
                where(translatable: self).destroy_all
            end
          end
        end
      end
    end
  end
end
