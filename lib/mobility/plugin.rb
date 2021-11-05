# frozen-string-literal: true
require "tsort"
require "set"
require "mobility/util"

module Mobility
=begin

Defines convenience methods on plugin module to hook into initialize/included
method calls on +Mobility::Pluggable+ instance.

- #initialize_hook: called after {Mobility::Pluggable#initialize}, with
  attribute names.
- #included_hook: called after {Mobility::Pluggable#included}. (This can be
  used to include any module(s) into the backend class, see
  {Mobility::Plugins::Backend}.)

To define methods on the backend, the plugin +included+ hook also looks for
constants named +BackendMethods+ and/or +BackendClassMethods+ in the plugin
namespace. If it finds these, *and* no included hook has been defined on the
plugin, then it auto-generates an included hook in which the backend class
includes/extends these modules.

The module also includes a +configure+ class method to apply plugins to a
pluggable ({Mobility::Pluggable} instance), with a block.

@example Defining a plugin
  module MyPlugin
    extend Mobility::Plugin

    initialize_hook do |*names|
      names.each do |name|
        define_method "#{name}_foo" do
          # method body
        end
      end
    end

    included_hook do |klass, backend_class|
      backend_class.include MyBackendMethods
      klass.include MyModelMethods
    end
  end

@example With +BackendMethods+ module
  module MyPlugin
    extend Mobility::Plugin

    module BackendMethods
      def read(locale, **)
        # ...
      end

      def write(locale, value, **)
        # ...
      end
    end
  end

@example Configure an attributes class with plugins
  class Translations < Mobility::Translations
  end

  Mobility::Plugin.configure(Translations) do
    cache
    fallbacks
  end

  Translations.included_modules
  #=> [Mobility::Plugins::Fallbacks, Mobility::Plugins::Cache, ...]
=end
  module Plugin
    class << self
      # Configure a pluggable {Mobility::Pluggable} with a block. Yields to a
      # clean room where plugin names define plugins on the module. Plugin
      # dependencies are resolved before applying them.
      #
      # @param [Class, Module] pluggable
      # @param [Hash] defaults Plugin defaults hash to update
      # @yield Block to define plugins
      # @return [Hash] Updated plugin defaults
      # @raise [Mobility::Plugin::CyclicDependency] if dependencies cannot be met
      # @example
      #   Mobility::Plugin.configure(Translations) do
      #     cache
      #     fallbacks [:en, :de]
      #   end
      def configure(pluggable, defaults = pluggable.defaults, &block)
        DependencyResolver.new(pluggable, defaults).call(&block)
      end
    end

    def initialize_hook(&block)
      plugin = self

      define_method :initialize do |*args, **options|
        super(*args, **options)

        class_exec(*args, &block) if plugin.dependencies_satisfied?(self.class)
      end
    end

    def included_hook(&block)
      plugin = self

      define_method :included do |klass|
        super(klass).tap do |backend_class|
          if plugin.dependencies_satisfied?(self.class)
            class_exec(klass, backend_class, &block)
          end
        end
      end
    end

    def included(pluggable)
      if defined?(@default) && !pluggable.defaults.has_key?(name = Plugins.lookup_name(self))
        pluggable.defaults[name] = @default
      end
      if !method_defined?(:included) &&
          (defined?(self::BackendMethods) || defined?(self::BackendClassMethods))
        plugin = self
        included_hook do |_, backend_class|
          backend_class.include(plugin::BackendMethods) if defined?(plugin::BackendMethods)
          backend_class.extend(plugin::BackendClassMethods) if defined?(plugin::BackendClassMethods)
        end
      end
      super
    end

    def dependencies
      @dependencies ||= {}
    end

    def default(value)
      @default = value
    end

    # Method called when defining plugins to assign a default based on
    # arguments and keyword arguments to the plugin method. By default, we
    # simply assign the first argument, but plugins can opt to customize this
    # if additional arguments or keyword arguments are required.
    # (The backend plugin uses keyword arguments to set backend options.)
    #
    # @param [Hash] defaults
    # @param [Symbol] key Plugin key on hash
    # @param [Array] args Method arguments
    def configure_default(defaults, key, *args)
      defaults[key] = args[0] unless args.empty?
    end

    # Does this class include all plugins this plugin depends (directly) on?
    # @param [Class] klass Pluggable class
    def dependencies_satisfied?(klass)
      plugin_keys = klass.included_plugins.map { |plugin| Plugins.lookup_name(plugin) }
      (dependencies.keys - plugin_keys).none?
    end

    # Specifies a dependency of this plugin.
    #
    # By default, the dependency is included (include: true). Passing +:before+
    # or +:after+ will ensure the dependency is included before or after this
    # plugin.
    #
    # Passing +false+ does not include the dependency, but checks that it has
    # been included when running include and initialize hooks (so hooks will
    # not run for this plugin if it has not been included). In other words:
    # disable this plugin unless this dependency has been included elsewhere.
    # (Note that this check is not applied recursively.)
    #
    # @param [Symbol] plugin Name of plugin dependency
    # @option [TrueClass, FalseClass, Symbol] include
    def requires(plugin, include: true)
      unless [true, false, :before, :after].include?(include)
        raise ArgumentError, "requires 'include' keyword argument must be one of: true, false, :before or :after"
      end
      dependencies[plugin] = include
    end

    DependencyResolver = Struct.new(:pluggable, :defaults) do
      def call(&block)
        plugins = DSL.call(defaults, &block)
        tree = create_tree(plugins)

        pluggable.include(*tree.tsort.reverse) unless tree.empty?
      rescue TSort::Cyclic => e
        raise_cyclic_dependency!(e.message)
      end

      private

      def create_tree(plugins)
        DependencyTree.new.tap do |tree|
          visited = included_plugins
          plugins.each { |plugin| traverse(tree, plugin, visited) }
        end
      end

      def included_plugins
        pluggable.included_modules.grep(Plugin)
      end

      # Recursively traverse dependencies and add their dependencies to tree
      def traverse(tree, plugin, visited)
        return if visited.include?(plugin)

        tree.add(plugin)

        plugin.dependencies.each do |dep_name, include_order|
          next unless include_order
          dep = Plugins.load_plugin(dep_name)
          add_dependency(plugin, dep, tree, include_order)

          traverse(tree, dep, visited << plugin)
        end
      end

      def add_dependency(plugin, dep, tree, include_order)
        case include_order
        when :before
          tree[plugin] += [dep]
        when :after
          check_after_dependency!(plugin, dep)
          tree.add(dep)
          tree[dep] += [plugin]
        end
      end

      def check_after_dependency!(plugin, dep)
        if included_plugins.include?(dep)
          message = "'#{name(dep)}' plugin must come after '#{name(plugin)}' plugin"
          raise DependencyConflict, append_pluggable_name(message)
        end
      end

      def raise_cyclic_dependency!(error_message)
        components = error_message.scan(/(?<=\[).*(?=\])/).first
        names = components.split(', ').map! do |plugin|
          name(Object.const_get(plugin)).to_s
        end
        message = "Dependencies cannot be resolved between: #{names.sort.join(', ')}"
        raise CyclicDependency, append_pluggable_name(message)
      end

      def append_pluggable_name(message)
        pluggable.name ? "#{message} in #{pluggable}" : message
      end

      def name(plugin)
        Plugins.lookup_name(plugin)
      end

      class DependencyTree < Hash
        include ::TSort
        NO_DEPENDENCIES = Set.new.freeze

        def add(key)
          self[key] ||= NO_DEPENDENCIES
        end

        alias tsort_each_node each_key

        def tsort_each_child(dep, &block)
          self.fetch(dep, []).each(&block)
        end
      end

      class DSL < BasicObject
        def self.call(defaults, &block)
          new(plugins = ::Set.new, defaults).instance_eval(&block)
          plugins
        end

        def initialize(plugins, defaults)
          @plugins = plugins
          @defaults = defaults
        end

        def method_missing(m, *args)
          plugin = Plugins.load_plugin(m)
          @plugins << plugin
          plugin.configure_default(@defaults, m, *args)
        end
      end
    end
    private_constant :DependencyResolver

    class DependencyConflict < Mobility::Error; end
    class CyclicDependency < DependencyConflict; end
  end
end
