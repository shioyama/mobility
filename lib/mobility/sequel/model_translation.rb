module Mobility
  module Sequel
    module ModelTranslation
      def self.included(base)
        base.plugin :validation_helpers
      end

      def validate
        super
        validates_presence [:locale]
      end
    end
  end
end
