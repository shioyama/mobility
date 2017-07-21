module Mobility
  module Backend
=begin

Backend which does absolutely nothing. Mostly for testing purposes.

=end
    class Null
      include Backend

      # @!group Backend Accessors
      # @return [NilClass]
      def read(_locale, _options = {}); end

      # @return [NilClass]
      def write(_locale, _value, _options = {}); end
      # @!endgroup

      # @!group Backend Configuration
      def self.configure(_options); end
      # @!endgroup
    end
  end
end
