module Helpers
  def stringify_keys(hash)
    result = Hash.new
    hash.each_key { |key| result[key.to_s] = hash[key] }
    result
  end

  def self.included(base)
    base.extend LazyDescribedClass
  end

  # Reset I18n.fallbacks to nil, necessary in case the default locale is
  # changed since I18n.fallbacks implicitly stores the previous default locale
  # as @@defaults.
  def reset_i18n_fallbacks
    I18n.class_variable_set(:@@fallbacks, nil)
  end

  # Define as helper to make it easy in the future to update if this changes.
  def backend_for(object, name)
    object.mobility_backends[name]
  end

  module LazyDescribedClass
    # lazy-load described_class if it's a string
    def described_class
      klass = super
      return klass if klass

      # crawl up metadata tree looking for description that can be constantized
      this_metadata = metadata
      while this_metadata do
        candidate = this_metadata[:description_args].first
        begin
          return Object.const_get(candidate) if String === candidate
        rescue NameError, NoMethodError
        end
        this_metadata = this_metadata[:parent_example_group]
      end
    end
  end

  module Backend
    def include_backend_examples *args
      it_behaves_like "Mobility backend", *args
    end

    def include_dup_examples *args
      it_behaves_like "dupable model", *args
    end

    def include_cache_key_examples *args
      it_behaves_like "cache key", *args
    end

    def backend_listener(listener)
      Class.new.tap do |klass|
        klass.class_eval do
          include Mobility::Backend
          define_method :read do |*args, **opts|
            listener.read(*args, **opts)
          end

          define_method :write do |*args, **opts|
            listener.write(*args, **opts)
          end
        end
      end
    end
  end

  module Plugins
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Pass plugin names as arguments if no plugin defaults to set
      def plugins(*args, &block)
        if args.empty?
          plugins_block = block
        else
          plugins_block = proc do
            args.each { |arg| __send__ arg }
          end
        end
        let(:translations_class) do
          Class.new(Mobility::Translations).tap do |attrs|
            attrs.plugins(&plugins_block)
          end
        end
      end
    end
  end

  # Simple module for setting up translated attributes on a class
  module Translates
    def self.included(base)
      base.extend ClassMethods
    end

    def translates(klass, *attribute_names, **options)
      raise ArgumentError, "You have not declared plugins for this test" unless respond_to?(:translations_class)
      klass.include translations_class.new(*attribute_names, **options)
      klass
    end

    module ClassMethods
      def translates(*attribute_names)
        unless method_defined?(:translations)
          let(:translations) do
            translations_class.new(
              *attribute_names,
              **(respond_to?(:translation_options) ? translation_options : {})
            )
          end
        end

        unless method_defined?(:model_class)
          let(:model_class) do
            Class.new.tap do |klass|
              klass.include translations
            end
          end
        end

        unless method_defined?(:instance)
          let(:instance) { model_class.new }
        end
      end
    end
  end

  module ActiveRecord
    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "AR Model with translated scope", *args
    end

    def include_serialization_examples *args
      it_behaves_like "AR Model with serialized translations", *args
    end

    def include_validation_examples *args
      it_behaves_like "AR Model validation", *args
    end
  end

  module Sequel
    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
      it_behaves_like "Sequel model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "Sequel Model with translated dataset", *args
    end

    def include_serialization_examples *args
      it_behaves_like "Sequel Model with serialized translations", *args
    end
  end

  module Generators
    def version_string
      "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}"
    end
  end

  module PluginSetup
    include Backend

    def self.included(base)
      base.include Helpers::Translates
      base.extend ClassMethods

      base.include Helpers::Plugins
    end

    module ClassMethods
      DUMMY_NAMES = ["dummy"].freeze

      # Define new plugin, register it, then remove after spec is done
      def define_plugins(*names)
        names.each do |name|
          let!(name) do
            Module.new.tap do |mod|
              mod.extend Mobility::Plugin
              Mobility::Plugins.register_plugin(name, mod)
              stub_const(name.to_s.capitalize, mod)
            end
          end
        end

        after do
          plugins = Mobility::Plugins.instance_variable_get(:@plugins)
          names.each { |name| plugins.delete(name) }
        end
      end
      alias_method :define_plugin, :define_plugins

      # Sets up attributes module with a listener to listen on reads/writes to the
      # backend.
      def plugin_setup(*attribute_names, **kwargs)
        attribute_names = DUMMY_NAMES if attribute_names.empty?

        let(:translation_options) { { backend: backend_class, **kwargs } }

        let(:listener) { double(:backend) }
        let(:backend_class) { backend_listener(listener) }
        let(:backend) { instance.mobility_backends[attribute_names.first] }
        attribute_names.each { |name| let(:"#{name}_backend") { instance.send("#{name}_backend") } }

        translates(*attribute_names)
      end
    end
  end
end
