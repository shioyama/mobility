# frozen_string_literal: true
require "mobility/backends/active_record"
require "mobility/backends/hash_valued"
require "mobility/backends/serialized"

module Mobility
  module Backends
=begin

Implements {Mobility::Backends::Serialized} backend for ActiveRecord models.

@example Define attribute with serialized backend
  class Post < ActiveRecord::Base
    extend Mobility
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
      include HashValued

      # @!group Backend Configuration
      # @param (see Backends::Serialized.configure)
      # @option (see Backends::Serialized.configure)
      # @raise (see Backends::Serialized.configure)
      def self.configure(options)
        super
        Serialized.configure(options)
      end
      # @!endgroup

      def self.build_node(attr, _locale)
        raise ArgumentError,
          "You cannot query on mobility attributes translated with the Serialized backend (#{attr})."
      end

      setup do |attributes, options|
        coder = { yaml: YAMLCoder, json: JSONCoder }[options[:format]]
        attributes.each { |attribute| serialize (options[:column_affix] % attribute), coder }
      end

      # @!group Cache Methods
      # Returns column value as a hash
      # @return [Hash]
      def translations
        model.read_attribute(column_name)
      end

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

    register_backend(:active_record_serialized, ActiveRecord::Serialized)
  end
end
