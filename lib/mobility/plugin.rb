# frozen-string-literal: true

module Mobility
=begin

Defines convenience methods on plugin module to hook into initialize/included
method calls on +Mobility::Attributes+ instance.

- #initialize_hook: called after {{Mobility::Attributes#initialize}, with
  attribute names and options hash.
- #included_hook: called after {{Mobility::Attributes#included}, with included
  class (model class) and backend class. (Use this hook to include any
  module(s) into backend class.)

Also includes a +configure+ class method to apply plugins to a pluggable
instance (+Mobility::Attributes+), with a block.

@example Defining a plugin
  module MyPlugin
    extend Mobility::Plugin

    initialize_hook do |*names, **options|
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

@example Configure a pluggable class with plugins
  class TranslatedAttributes < Mobility::Attributes
  end

  Mobility::Plugin.configure(TranslatedAttributes) do
    cache
    fallbacks
  end

  TranslatedAttributes.included_modules
  #=> [Mobility::Plugins::Fallbacks, Mobility::Plugins::Cache, ...]
=end
  module Plugin
    class << self
      # Configure a pluggable {Mobility::Attributes} with a block. Yields to a
      # clean room where plugin names define plugins on the module. Plugin
      # dependencies are resolved before applying them.
      #
      # @param [Class, Module] pluggable
      # @param [Hash] defaults Plugin defaults hash to update
      # @return [Hash] Updated plugin defaults
      # @raise [Mobility::Plugin::CyclicDependency] if dependencies cannot be met
      # @example
      #   Mobility::Plugin.configure(TranslatedAttributes) do
      #     cache
      #     fallbacks default: [:en, :de]
      #   end
      def configure(pluggable, defaults = {}, &block)
        DependencyResolver.new(pluggable, defaults).call(&block)
      end
    end

    def initialize_hook(&block)
      key = plugin_key
      define_method :initialize do |*names, **options|
        super(*names, **options)
        class_exec(*names, **@options.slice(key), &block)
      end
    end

    def included_hook(&block)
      key = plugin_key
      define_method :included do |klass|
        super(klass).tap do |backend_class|
          class_exec(klass, backend_class, **@options.slice(key), &block)
        end
      end
    end

    def dependencies
      @dependencies ||= {}
    end

    def depends_on(plugin, include: nil)
      unless [nil, :before, :after].include?(include)
        raise ArgumentError, "depends_on 'include' keyword argument must be nil, :before or :after"
      end
      dependencies[plugin] = include
    end

    private

    def plugin_key
      Util.underscore(to_s.split('::').last).to_sym
    end

    DependencyResolver = Struct.new(:pluggable, :defaults) do
      def call(&block)
        plugins = DSL.call(defaults, &block)
        tree = create_tree(plugins)

        pluggable.include(*tree.tsort.reverse) unless tree.empty?
        defaults
      rescue TSort::Cyclic => e
        raise_cyclic_dependency!(e.message)
      end

      private

      attr_reader :tree

      def create_tree(plugin_names)
        DependencyTree.new.tap do |tree|
          visited = included_plugins
          plugin_names.each do |plugin_name|
            plugin = Plugins.load_plugin(plugin_name)
            add_dependency(tree, plugin, plugin_name, visited)
          end
        end
      end

      def included_plugins
        pluggable.included_modules.grep(Plugin)
      end

      # Recursively add dependencies and their dependencies to tree
      def add_dependency(tree, plugin, plugin_name, visited)
        return if visited.include?(plugin)

        tree.add(plugin)

        plugin.dependencies.each do |dep_name, load_order|
          dep = Plugins.load_plugin(dep_name)

          case load_order
          when :before
            tree[plugin] += [dep]
          when :after
            check_after_dependency!(dep, dep_name, plugin_name)
            tree.add(dep)
            tree[dep] += [plugin]
          end

          add_dependency(tree, dep, dep_name, visited << plugin)
        end
      end

      def check_after_dependency!(dep, dep_name, plugin_name)
        if included_plugins.include?(dep)
          message = "'#{dep_name}' plugin must come after '#{plugin_name}' plugin"
          raise DependencyConflict, append_pluggable_name(message)
        end
      end

      def raise_cyclic_dependency!(error_message)
        components = error_message.scan(/(?<=\[).*(?=\])/).first
        names = components.split(', ').map! do |plugin|
          Plugins.lookup_name(Object.const_get(plugin)).to_s
        end
        message = "Dependencies cannot be resolved between: #{names.sort.join(', ')}"
        raise CyclicDependency, append_pluggable_name(message)
      end

      def append_pluggable_name(message)
        pluggable.name ? "#{message} in #{pluggable}" : message
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

        def method_missing(m, *_args, **options)
          @plugins << m
          @defaults[m] = options[:default] if options.has_key?(:default)
        end
      end
    end
    private_constant :DependencyResolver

    class DependencyConflict < Mobility::Error; end
    class CyclicDependency < DependencyConflict; end
  end
end
