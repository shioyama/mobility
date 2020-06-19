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
      # @raise [Mobility::Plugin::CyclicDependency] if dependencies cannot be met
      # @example
      #   Mobility::Plugin.configure(TranslatedAttributes) do
      #     cache
      #     fallbacks
      #   end
      def configure(pluggable, &block)
        DependencyResolver.new(pluggable).call(&block)
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

    DependencyResolver = Struct.new(:pluggable) do
      def call(&block)
        plugin_names = DSL.call(&block)
        tree = create_tree(plugin_names)

        # Add any previously included plugins as dependencies of new plugins,
        # ensuring any dependencies between them are met.
        plugins = included_plugins
        tree.each_key { |plugin| tree[plugin] += plugins }

        pluggable.include(*tree.tsort.reverse) unless tree.empty?
      rescue TSort::Cyclic => e
        components = e.message.scan(/(?<=\[).*(?=\])/).first
        raise CyclicDependency, "Dependencies cannot be resolved between: #{components}"
      end

      private

      def create_tree(plugin_names)
        DependencyTree.new.tap do |tree|
          visited = included_plugins
          plugin_names.each do |name|
            plugin = Plugins.load_plugin(name)
            add_dependency(tree, plugin, visited)
          end
        end
      end

      attr_reader :tree

      def included_plugins
        pluggable.included_modules.grep(Plugin)
      end

      # Recursively add dependencies and their dependencies to tree
      def add_dependency(tree, plugin, visited)
        return if visited.include?(plugin)

        tree.add(plugin)

        plugin.dependencies.each do |dep, load_order|
          dep = Plugins.load_plugin(dep)

          case load_order
          when :before
            tree[plugin] += [dep]
          when :after
            tree.add(dep)
            tree[dep] += [plugin]
          end

          add_dependency(tree, dep, visited << plugin)
        end
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
        def self.call(&block)
          ::Set.new.tap do |plugins|
            new(plugins).instance_eval(&block)
          end
        end

        def initialize(plugins)
          @plugins = plugins
        end

        def method_missing(m, *)
          @plugins << m
        end
      end
    end
    private_constant :DependencyResolver

    class CyclicDependency < Mobility::Error; end
  end
end
