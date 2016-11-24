module Mobility
  module Backend
    module Fallbacks
      def read(locale, options = {})
        return super if options[:fallbacks] == false
        fallbacks[locale].detect do |locale|
          value = super(locale)
          break value if value.to_s.present?
        end
      end

      private

      def fallbacks
        @fallbacks ||= Mobility.default_fallbacks
      end
    end
  end
end
