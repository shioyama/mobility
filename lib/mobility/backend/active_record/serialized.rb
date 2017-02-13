module Mobility
  module Backend
=begin

Implements {Mobility::Backend::Serialized} backend for ActiveRecord models.

@example Define attribute with serialized backend
  class Post < ActiveRecord::Base
    translates :title, backend: :serialized, format: :yaml
  end

@example Read and write attribute translations
  post = Post.create(title: "foo")
  post.title
  #=> "foo"
  Mobility.locale = :ja
  post.title = "あああ"
  post.save
  post.read_attribute(:title)      # get serialized value
  #=> {:en=>"foo", :ja=>"あああ"}

=end
    class ActiveRecord::Serialized
      include Backend

      autoload :QueryMethods, 'mobility/backend/active_record/serialized/query_methods'

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
        coder = { yaml: YAMLCoder, json: JSONCoder }[options[:format]]
        attributes.each { |attribute| serialize attribute, coder }

        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend extension
      end

      # @!group Cache Methods
      # Returns column value as a hash
      # @return [Hash]
      def translations
        model.read_attribute(attribute)
      end
      alias_method :new_cache, :translations

      # @return [Boolean]
      def write_to_cache?
        true
      end
      # @!endgroup

      %w[yaml json].each do |format|
        class_eval <<-EOM, __FILE__, __LINE__ + 1
          class #{format.upcase}Coder
            def self.dump(obj)
              Serialized.serializer_for(:#{format}).call(obj)
            end

            def self.load(obj)
              return {} if obj.nil?
              Serialized.deserializer_for(:#{format}).call(obj)
            end
          end
        EOM
      end
    end
  end
end
