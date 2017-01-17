module Mobility
  module Backend
    class Null
      include Backend

      def read(*); end
      def write(*); end
      def self.configure!(*); end
    end
  end
end
