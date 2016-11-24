module Mobility
  module Backend
    class Null
      include Base

      def read(locale); end
      def write(locale, value); end
    end
  end
end
