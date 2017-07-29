module Mobility
  module Backend
=begin

Internal class used by ActiveRecord backends that store values as a hash.

=end
    class ActiveRecord::HashValued
      include ActiveRecord

      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, _ = {})
        translations[locale]
      end

      # @!macro backend_writer
      def write(locale, value, _ = {})
        translations[locale] = value
      end
      # @!endgroup

      def translations
        model.read_attribute(attribute)
      end

      setup do |attributes|
        attributes.each { |attribute| store attribute, coder: Coder }
      end

      class Coder
        def self.dump(obj)
          if obj.is_a? Hash
            obj.inject({}) do |translations, (locale, value)|
              translations[locale] = value if value.present?
              translations
            end
          else
            raise ArgumentError, "Attribute is supposed to be a Hash, but was a #{obj.class}. -- #{obj.inspect}"
          end
        end

        def self.load(obj)
          obj
        end
      end
    end
  end
end
