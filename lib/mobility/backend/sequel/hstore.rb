require 'mobility/backend/sequel/hash_valued'

module Mobility
  module Backend
    class Sequel::Hstore < Sequel::HashValued
      autoload :QueryMethods, 'mobility/backend/sequel/hstore/query_methods'

      def write(locale, value, **options)
        translations[locale.to_s] = value && value.to_s
      end

      setup do |attributes, options|
        extension = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().with_extend(QueryMethods.new(attributes, options))
          end
        end
        extend extension
      end
    end
  end
end
