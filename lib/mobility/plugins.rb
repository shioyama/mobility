module Mobility
=begin

Plugins allow modular customization of backends independent of the backend
itself. They are enabled through {Mobility::Translations.plugins} (delegated to
from {Mobility.configure}), which takes a block within which plugins can be
declared in any order (dependencies will be resolved).

=end
  module Plugins
    @plugins = {}
    @names = {}

    class << self
      # @param [Symbol] name Name of plugin to load.
      def load_plugin(name)
        return name if Module === name || name.nil?

        unless (plugin = @plugins[name])
          require "mobility/plugins/#{name}"
          raise LoadError, "plugin #{name} did not register itself correctly in Mobility::Plugins" unless (plugin = @plugins[name])
        end
        plugin
      end

      # @param [Module] plugin Plugin module to lookup. Plugin must already be loaded.
      def lookup_name(plugin)
        @names.fetch(plugin)
      end

      def register_plugin(name, plugin)
        @plugins[name] = plugin
        @names[plugin] = name
      end

      class LoadError < Error; end
    end
  end
end
