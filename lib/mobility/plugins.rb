module Mobility
=begin

Plugins allow modular customization of backends independent of the backend
itself. They are enabled through the {Configuration.plugins} configuration
setting, which takes an array of symbols corresponding to plugin names. The
order of these names is important since it determines the order in which
plugins will be applied.

So if our {Configuration.plugins} is an array +[:foo]+, and we call
`translates` on our model, +Post+, like this:

  class Post
    translates :title, foo: true
  end

Then the +Foo+ plugin will be applied with the option value +true+. Applying a
module calls a class method, +apply+ (in this case +Foo.apply+), which takes
two arguments:

- an instance of the {Attributes} class, +attributes+, from which the backend
  can configure the backend class (+attributes.backend_class+) and the model
  (+attributes.model_class+), and the +attributes+ module itself (which
  will be included into the backend).
- the value of the +option+ passed into the model with +translates+ (in this
  case, +true+).

Typically, the plugin will include a module into either
+attributes.backend_class+ or +attributes+ itself, configured according to the
option value. For examples, see classes under the {Mobility::Plugins} namespace.

=end
  module Plugins
    @plugins = {}
    @names = {}

    class << self
      # @param [Symbol] name Name of plugin to load.
      def load_plugin(name)
        unless (plugin = @plugins[name])
          require "mobility/plugins/#{name}"
          raise Error, "plugin #{name} did not register itself correctly in Mobility::Plugins" unless (plugin = @plugins[name])
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
    end
  end
end
