require 'mobility/backend/sequel/hash_valued'

module Mobility
  module Backend
    class Sequel::Jsonb < Sequel::HashValued
      autoload :QueryMethods, 'mobility/backend/sequel/jsonb/query_methods'

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
