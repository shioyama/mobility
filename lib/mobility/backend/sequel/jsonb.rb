module Mobility
  module Backend
    class Sequel::Jsonb
      include Backend

      autoload :QueryMethods, 'mobility/backend/sequel/jsonb/query_methods'

      def read(locale, **options)
        translations[locale.to_s]
      end

      def write(locale, value, **options)
        translations[locale.to_s] = value && value.to_s
      end

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

        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension
      end

      def translations
        model.send("#{attribute}_before_mobility")
      end
      alias_method :new_cache, :translations

      def write_to_cache?
        true
      end
    end
  end
end
