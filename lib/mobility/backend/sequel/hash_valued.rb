module Mobility
  module Backend
=begin

Internal class used by Sequel backends that store values as a hash.

=end
    class Sequel::HashValued
      include Backend

      # @!macro backend_reader
      def read(locale, **options)
        translations[locale.to_s]
      end

      # @!macro backend_writer
      def write(locale, value, **options)
        translations[locale.to_s] = value
      end

      # @!group Cache Methods
      def translations
        model.send("#{attribute}_before_mobility")
      end
      alias_method :new_cache, :translations

      # @return [Boolean]
      def write_to_cache?
        true
      end
      # @!endgroup

      setup do |attributes, options|
        method_overrides = Module.new do
          define_method :initialize_set do |values|
            attributes.each { |attribute| send(:"#{attribute}_before_mobility=", {}) }
            super(values)
          end
          define_method :before_validation do
            attributes.each do |attribute|
              send("#{attribute}_before_mobility").delete_if { |_, v| v.blank? }
            end
            super()
          end
        end
        include method_overrides
        include Mobility::Sequel::ColumnChanges.new(attributes)
      end
    end
  end
end
