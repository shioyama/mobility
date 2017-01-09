module Mobility
  module Backend
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

      FORMATS = Hash[%i[yaml json].map { |format| [format, [serializer_for(format), deserializer_for(format)]] }]
    end
  end
end
