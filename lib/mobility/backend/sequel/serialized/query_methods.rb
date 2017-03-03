module Mobility
  module Backend
    class Sequel::Serialized::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, **)
        super
        attributes_extractor = @attributes_extractor
        cond_checker = @cond_checker = lambda do |cond|
          if i18n_keys = attributes_extractor.call(cond)
            raise ArgumentError,
              "You cannot query on mobility attributes translated with the Serialized backend (#{i18n_keys.join(", ")})."
          end
        end

        define_method :where do |*cond, &block|
          cond_checker.call(cond.first) || super(*cond, &block)
        end
      end
    end
  end
end
