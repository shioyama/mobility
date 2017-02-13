module Mobility
  module Backend
=begin

Implements {Mobility::Backend::Serialized} backend for Sequel models, using the
Sequel serialization plugin.

@see http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/Serialization.html Sequel serialization plugin
@see http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/SerializationModificationDetection.html Sequel serialization_modification_detection plugin

@example Define attribute with serialized backend
  class Post < Sequel::Model
    include Mobility
    translates :title, backend: :serialized, format: :yaml
  end

@example Read and write attribute translations
  post = Post.create(title: "foo")
  post.title
  #=> "foo"
  Mobility.locale = :ja
  post.title = "あああ"
  post.save
  post.deserialized_values[:title]       # get deserialized value
  #=> {:en=>"foo", :ja=>"あああ"}
  post.title_before_mobility             # get serialized value
  #=> "---\n:en: foo\n:ja: \"あああ\"\n"

=end
    class Sequel::Serialized
      include Backend

      autoload :QueryMethods, 'mobility/backend/sequel/serialized/query_methods'

      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, **options)
        translations[locale]
      end

      # @!macro backend_reader
      def write(locale, value, **options)
        translations[locale] = value
      end
      # @!endgroup

      # @!group Backend Configuration
      # @option options [Symbol] format (:yaml) Serialization format
      # @raise [ArgumentError] if a format other than +:yaml+ or +:json+ is passed in
      def self.configure!(options)
        options[:format] ||= :yaml
        options[:format] = options[:format].downcase.to_sym
        raise ArgumentError, "Serialized backend only supports yaml or json formats." unless [:yaml, :json].include?(options[:format])
      end
      # @!endgroup

      setup do |attributes, options|
        format = options[:format]
        plugin :serialization
        plugin :serialization_modification_detection

        attributes.each do |_attribute|
          attribute = _attribute.to_sym
          self.serialization_map[attribute] = Serialized.serializer_for(format)
          self.deserialization_map[attribute] = Serialized.deserializer_for(format)
        end

        method_overrides = Module.new do
          define_method :initialize_set do |values|
            attributes.each { |attribute| send(:"#{attribute}_before_mobility=", {}.send(:"to_#{format}")) }
            super(values)
          end
        end
        include method_overrides

        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension

        include SerializationModificationDetectionFix
      end

      # Returns deserialized column value
      # @return [Hash]
      def translations
        _attribute = attribute.to_sym
        if model.deserialized_values.has_key?(_attribute)
          model.deserialized_values[_attribute]
        elsif model.frozen?
          deserialize_value(_attribute, serialized_value)
        else
          model.deserialized_values[_attribute] = deserialize_value(_attribute, serialized_value)
        end
      end

      # @!group Cache Methods
      # @return [Hash]
      def new_cache
        translations
      end

      # @return [Boolean]
      def write_to_cache?
        true
      end
      # @!endgroup

      # @note The original serialization_modification_detection plugin sets
      #   +@original_deserialized_values+ to be +@deserialized_values+, which
      #   doesn't work. Setting it to a new empty hash seems to work better.
      module SerializationModificationDetectionFix
        def after_save
          super()
          @original_deserialized_values = {}
        end
      end

      private

      def deserialize_value(column, value)
        model.send(:deserialize_value, column, value)
      end

      def serialized_value
        model.send("#{attribute}_before_mobility")
      end
    end
  end
end
