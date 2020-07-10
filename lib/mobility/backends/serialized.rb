# frozen_string_literal: true
require "mobility/util"

module Mobility
  module Backends
=begin

Stores translations as serialized attributes in a single text column. This
implies that the translated values are not searchable, and thus this backend is
not recommended unless specific constraints prevent use of other solutions.

To use this backend, ensure that the model table has a text column on its table
with the same name as the translated attribute.

==Backend Options

===+format+

Format for serialization. Either +:yaml+ (default) or +:json+.

@see Mobility::Backends::ActiveRecord::Serialized
@see Mobility::Backends::Sequel::Serialized

=end
    module Serialized
      class << self

        # @!group Backend Configuration
        # @option options [Symbol] format (:yaml) Serialization format
        # @raise [ArgumentError] if a format other than +:yaml+ or +:json+ is passed in
        def configure(options)
          options[:format] ||= :yaml
          options[:format] = options[:format].downcase.to_sym
          raise ArgumentError, "Serialized backend only supports yaml or json formats." unless [:yaml, :json].include?(options[:format])
        end
        # @!endgroup

        def serializer_for(format)
          lambda do |obj|
            return if obj.nil?
            if obj.is_a? ::Hash
              obj = obj.inject({}) do |translations, (locale, value)|
                translations[locale] = value.to_s if Util.present?(value)
                translations
              end
            else
              raise ArgumentError, "Attribute is supposed to be a Hash, but was a #{obj.class}. -- #{obj.inspect}"
            end

            obj.send("to_#{format}")
          end
        end

        def deserializer_for(format)
          case format
          when :yaml
            lambda { |v| YAML.load(v) }
          when :json
            lambda { |v| JSON.parse(v, symbolize_names: true) }
          end
        end
      end

      def check_opts(opts)
        if keys = extract_attributes(opts)
          raise ArgumentError,
            "You cannot query on mobility attributes translated with the Serialized backend (#{keys.join(", ")})."
        end
      end
    end

    register_backend(:serialized, Serialized)
  end
end
