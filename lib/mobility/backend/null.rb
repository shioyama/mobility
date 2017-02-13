module Mobility
  module Backend
=begin

Backend which does absolutely nothing. Mostly for testing purposes.

=end
    class Null
      include Backend

      # @!group Backend Accessors
      # @return [NilClass]
      def read(*); end

      # @return [NilClass]
      def write(*); end
      # @!endgroup

      # @!group Backend Configuration
      def self.configure!(*); end
      # @!endgroup
    end
  end
end
