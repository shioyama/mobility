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

      # @!group Backend Configuration
      # @param (see Backends::Serialized.configure)
      # @option (see Backends::Serialized.configure)
      # @raise (see Backends::Serialized.configure)
      def self.configure(options)
        super
        Serialized.configure(options)
      end
      # @!endgroup

      def self.build_op(attr, _locale)
        raise ArgumentError,
          "You cannot query on mobility attributes translated with the Serialized backend (#{attr})."
      end

      setup do |attributes, options|
        format = options[:format]
        columns = attributes.map { |attribute| (options[:column_affix] % attribute).to_sym }

        plugin :serialization
        plugin :serialization_modification_detection

        columns.each do |column|
          self.serialization_map[column] = Serialized.serializer_for(format)
          self.deserialization_map[column] = Serialized.deserializer_for(format)
        end

        method_overrides = Module.new do
          define_method :initialize_set do |values|
            columns.each { |column| self[column] = {}.send(:"to_#{format}") }
            super(values)
          end
        end
        include method_overrides

        include SerializationModificationDetectionFix
      end

      # Returns deserialized column value
      # @return [Hash]
      def translations
        if model.deserialized_values.has_key?(column_name)
          model.deserialized_values[column_name]
        elsif model.frozen?
          deserialize_value(serialized_value)
        else
          model.deserialized_values[column_name] = deserialize_value(serialized_value)
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

      def deserialize_value(value)
        model.send(:deserialize_value, column_name, value)
      end

      def serialized_value
        model[column_name]
      end

      def column_name
        super.to_sym
      end
    end

    register_backend(:sequel_serialized, Sequel::Serialized)
  end
end
