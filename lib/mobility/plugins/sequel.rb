require "sequel"
require "sequel/plugins/mobility"
unless defined?(ActiveSupport::Inflector)
  # TODO: avoid automatically including the inflector extension
  require "sequel/extensions/inflector"
end
require "sequel/plugins/dirty"
require_relative "./sequel/backend"
require_relative "./sequel/dirty"
require_relative "./sequel/cache"
require_relative "./sequel/query"
require_relative "./sequel/column_fallback"

module Mobility
  module Plugins
=begin

Plugin for Sequel models. This plugin automatically requires sequel related
plugins, which are not actually "active" unless their base plugin (e.g. dirty
for sequel_dirty) is also enabled.

=end
    module Sequel
      extend Plugin

      requires :sequel_backend, include: :after
      requires :sequel_dirty
      requires :sequel_cache
      requires :sequel_query
      requires :sequel_column_fallback

      included_hook do |klass|
        unless sequel_class?(klass)
          name = klass.name || klass.to_s
          raise TypeError, "#{name} should be a subclass of Sequel::Model to use the sequel plugin"
        end
      end

      private

      def sequel_class?(klass)
        klass < ::Sequel::Model
      end
    end

    register_plugin(:sequel, Sequel)
  end
end
