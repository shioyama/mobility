module Mobility
  module Backend
=begin

Stores translations as serialized attributes in a single text column. This
implies that the translated values are not searchable, and thus this backend is
not recommended unless specific constraints prevent use of other solutions.

To use this backend, ensure that the model table has a text column on its table
with the same name as the translated attribute.

==Backend Options

===+format+

Format for serialization. Either +:yaml+ (default) or +:json+.

@see Mobility::Backend::ActiveRecord::Serialized
@see Mobility::Backend::Sequel::Serialized

=end
    module Serialized
      include OrmDelegator

      class << self
        def serializer_for(format)
          lambda do |obj|
            return if obj.nil?
            if obj.is_a? Hash
              obj = obj.inject({}) do |translations, (locale, value)|
                translations[locale] = value.to_s if value.present?
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
    end
  end
end
