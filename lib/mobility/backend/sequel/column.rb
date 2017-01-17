module Mobility
  module Backend
    class Sequel::Column
      autoload :QueryMethods, 'mobility/backend/sequel/column/query_methods'

      include Base
      include Mobility::Backend::Column

      def self.configure!(options)
        options[:locale_accessors] = false
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
