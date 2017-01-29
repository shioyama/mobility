module Mobility
  module Backend
    class ActiveRecord::Hstore::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        super
        attributes_extractor = @attributes_extractor

        define_method :where! do |opts, *rest|
          super(opts, *rest)
        end
      end

      def extended(relation)
        super
      end
    end
  end
end
