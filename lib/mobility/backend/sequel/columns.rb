module Mobility
  module Backend
    class Sequel::Columns
      autoload :QueryMethods, 'mobility/backend/sequel/columns/query_methods'

      include Base
      include Mobility::Backend::Columns

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
