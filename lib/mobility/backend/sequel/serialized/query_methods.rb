module Mobility
  module Backend
    class Sequel::Serialized::QueryMethods < Sequel::QueryMethods
      def initialize(_attributes, **options)
        attributes = _attributes.map &:to_sym
        cond_checker = @cond_checker = lambda do |cond|
          if cond.is_a?(Hash) && (cond.keys & attributes).present?
            raise ArgumentError, "You cannot query on mobility attributes translated with the Serialized backend."
          end
        end

        define_method :where do |*cond, &block|
          cond_checker.call(cond.first) || super(*cond, &block)
        end
      end
    end
  end
end
