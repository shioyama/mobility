module Mobility
  module Backends
=begin

Backend which does absolutely nothing. Mostly for testing purposes.

=end
    class Null
      include Backend

      # @!group Backend Accessors
      # @return [NilClass]
      def read(_, _ = {}); end

      # @return [NilClass]
      def write(_, _, _ = {}); end
      # @!endgroup

      # @!group Backend Configuration
      def self.configure(_); end
      # @!endgroup
    end
  end
end
