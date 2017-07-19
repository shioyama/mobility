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
      include ActiveRecord

      require 'mobility/backend/active_record/serialized/query_methods'

      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, **_)
        translations[locale]
      end

      # @!macro backend_reader
      def write(locale, value, **_)
        translations[locale] = value
      end
      # @!endgroup

      # @see Backend::Serialized
      def self.configure(options)
        Serialized.configure(options)
      end
      # @!endgroup

      setup do |attributes, options|
        coder = { yaml: YAMLCoder, json: JSONCoder }[options[:format]]
        attributes.each { |attribute| serialize attribute, coder }
      end

      setup_query_methods(QueryMethods)

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
