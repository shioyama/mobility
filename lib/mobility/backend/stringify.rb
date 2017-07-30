module Mobility
  module Backend
    module Stringify
      def read(locale, options = {})
        super(locale.to_s, options)
      end

      def write(locale, value, options = {})
        super(locale.to_s, value, options)
      end
    end
  end
end
