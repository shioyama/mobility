module Mobility
  module Backend
    class Null
      include Base

      def read(locale, **options); end
      def write(locale, value, **options); end
      def self.configure!(options); end
    end
  end
end
