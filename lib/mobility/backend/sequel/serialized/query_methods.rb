module Mobility
  module Backend
    class Sequel::Serialized::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **)
        super
        attributes_extractor = @attributes_extractor
        cond_checker = Backend::Serialized.attr_checker(attributes_extractor)

        define_method :where do |*cond, &block|
          cond_checker.call(cond.first) || super(*cond, &block)
        end
      end
    end
  end
end
