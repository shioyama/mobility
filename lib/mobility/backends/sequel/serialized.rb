# frozen_string_literal: true
require "mobility/backends/sequel"
require "mobility/backends/hash_valued"
require "mobility/backends/serialized"

module Mobility
  module Backends
=begin

Implements {Mobility::Backends::Serialized} backend for Sequel models, using the
Sequel serialization plugin.

@see http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/Serialization.html Sequel serialization plugin
@see http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/SerializationModificationDetection.html Sequel serialization_modification_detection plugin

@example Define attribute with serialized backend
  class Post < Sequel::Model
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
  post.deserialized_values[:title]       # get deserialized value
  #=> {:en=>"foo", :ja=>"あああ"}
  post.title(super: true)                # get serialized value
  #=> "---\n:en: foo\n:ja: \"あああ\"\n"

=end
    class Sequel::Serialized
      include Sequel
      include HashValued

      require 'mobility/backends/sequel/serialized/query_methods'

      # @!group Backend Configuration
      # @param (see Backends::Serialized.configure)
      # @option (see Backends::Serialized.configure)
      # @raise (see Backends::Serialized.configure)
      def self.configure(options)
        Serialized.configure(options)
      end
      # @!endgroup

      setup do |attributes, options|
        format = options[:format]
        plugin :serialization
        plugin :serialization_modification_detection

        attributes.each do |attribute_|
          attribute = attribute_.to_sym
          self.serialization_map[attribute] = Serialized.serializer_for(format)
          self.deserialization_map[attribute] = Serialized.deserializer_for(format)
        end

        method_overrides = Module.new do
          define_method :initialize_set do |values|
            attributes.each { |attribute| self[attribute.to_sym] = {}.send(:"to_#{format}") }
            super(values)
          end
        end
        include method_overrides

        include SerializationModificationDetectionFix
      end

      setup_query_methods(QueryMethods)

      # Returns deserialized column value
      # @return [Hash]
      def translations
        attribute_ = attribute.to_sym
        if model.deserialized_values.has_key?(attribute_)
          model.deserialized_values[attribute_]
        elsif model.frozen?
          deserialize_value(attribute_, serialized_value)
        else
          model.deserialized_values[attribute_] = deserialize_value(attribute_, serialized_value)
        end
      end

      # @note The original serialization_modification_detection plugin sets
      #   +@original_deserialized_values+ to be +@deserialized_values+, which
      #   doesn't work. Setting it to a new empty hash seems to work better.
      module SerializationModificationDetectionFix
        def after_save
          super
          @original_deserialized_values = {}
        end
      end

      private

      def deserialize_value(column, value)
        model.send(:deserialize_value, column, value)
      end

      def serialized_value
        model[attribute.to_sym]
      end
    end
  end
end
