module Mobility
  module Backend
    class Null
      include Base

      def read(locale); end
      def write(locale, value); end
      def self.configure!(options); end
    end
  end
end
