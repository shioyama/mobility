module Mobility
=begin

Defines accessor methods to include on model class. Inspired by Traco's
+Traco::Attributes+ class.

Normally this class will be created through class methods defined using
{Mobility::Translates} accessor methods, and need not be created directly.
However, the class is central to how Mobility hooks into models to add
accessors and other methods, and should be useful as a reference when
understanding and designing backends.

==Including Attributes in a Class

Since {Attributes} is a subclass of +Module+, including an instance of it is
like including a module. Creating an instance like this:

  Attributes.new(:accessor, ["title"], backend: :my_backend, locale_accessors: [:en, :ja], cache: true, fallbacks: true)

will generate an anonymous module looking something like this:

  Module.new do
    def title_backend
      # Create a subclass of Mobility::Backends::MyBackend and include in it:
      # - Mobility::Plugins::Cache (from the +cache: true+ option)
      # - Mobility::Plugins::Fallbacks (from the +fallbacks: true+ option)
      # - Mobility::Plugins::Presence (by default, disabled by +presence: false+)
      # Then instantiate the backend, memoize it, and return it.
    end

    def title(**options)
      title_backend.read(Mobility.locale, **options).presence
    end

    def title?(**options)
      title_backend.read(Mobility.locale, **options).present?
    end

    def title=(value)
      title_backend.write(Mobility.locale, value.presence)
    end

    # Start Locale Accessors
    #
    def title_en(**options)
      title_backend.read(:en, **options).presence
    end

    def title_en?(**options)
      title_backend.read(:en, **options).present?
    end

    def title_en=(value)
      title_backend.write(:en, value.presence)
    end

    def title_ja(**options)
      title_backend.read(:ja, **options).presence
    end

    def title_ja?(**options)
      title_backend.read(:ja, **options).present?
    end

    def title_ja=(value)
      title_backend.write(:ja, value.presence)
    end
    # End Locale Accessors
  end

Including this module into a model class will then add the backend method, the
reader, writer and presence methods, and the locale accessor so the model
class.

==Setting up the Model Class

Accessor methods alone are of limited use without a hook to actually modify the
model class. This hook is provided by the {Backend::Setup#setup_model} method,
which is added to every backend class when it includes the {Backend} module.

Assuming the backend has defined a setup block by calling +setup+, this block
will be called when {Attributes} is {#included} in the model class, passed
attributes and options defined when the backend was defined on the model class.
This allows a backend to do things like (for example) define associations on a
model class required by the backend, as happens in the {Backends::KeyValue} and
{Backends::Table} backends.

The +setup+ block is also used to extend the query scope/dataset (+i18n+ by
default) with backend-specific query method support.

Since setup blocks are evaluated on the model class, it is possible that
backends can conflict (for example, overwriting previously defined methods).
Care should be taken to avoid defining methods on the model class, or where
necessary, ensure that names are defined in such a way as to avoid conflicts
with other backends.

=end
  class Attributes < Module
    # Method (accessor, reader or writer)
    # @return [Symbol] method
    attr_reader :method

    # Attribute names for which accessors will be defined
    # @return [Array<String>] Array of names
    attr_reader :names

    # Backend options
    # @return [Hash] Backend options
    attr_reader :options

    # Backend class
    # @return [Class] Backend class
    attr_reader :backend_class

    # Name of backend
    # @return [Symbol,Class] Name of backend, or backend class
    attr_reader :backend_name

    # Model class
    # @return [Class] Class of model
    attr_reader :model_class

    # @param [Symbol] method One of: [reader, writer, accessor]
    # @param [Array<String>] attribute_names Names of attributes to define backend for
    # @param [Hash] backend_options Backend options hash
    # @option backend_options [Class] model_class Class of model
    # @raise [ArgumentError] if method is not reader, writer or accessor
    def initialize(method, *attribute_names, backend: Mobility.default_backend, **backend_options)
      raise ArgumentError, "method must be one of: reader, writer, accessor" unless %i[reader writer accessor].include?(method)
      @method = method
      @options = Mobility.default_options.merge(backend_options)
      @names = attribute_names.map(&:to_s)
      raise Mobility::BackendRequired, "Backend option required if Mobility.config.default_backend is not set." if backend.nil?
      @backend_name = backend
    end

    # Setup backend class, include modules into model class, add this
    # attributes module to shared {Mobility::Wrapper} and setup model with
    # backend setup block (see {Mobility::Backend::Setup#setup_model}).
    # @param klass [Class] Class of model
    def included(klass)
      @model_class = @options[:model_class] = klass
      @backend_class = Class.new(get_backend_class(backend_name).for(model_class))

      @backend_class.configure(options) if @backend_class.respond_to?(:configure)

      Mobility.plugins.each do |name|
        plugin = get_plugin_class(name)
        plugin.apply(self, options[name])
      end

      names.each do |name|
        define_backend(name)
        define_reader(name) if %i[accessor reader].include?(method)
        define_writer(name) if %i[accessor writer].include?(method)
      end

      model_class.mobility << self
      backend_class.setup_model(model_class, names, options)
    end

    # Yield each attribute name to block
    # @yield [String] Attribute
    def each &block
      names.each(&block)
    end

    private

    def define_backend(attribute)
      backend_class_, options_ = backend_class, options
      define_method Backend.method_name(attribute) do
        @mobility_backends ||= {}
        @mobility_backends[attribute] ||= backend_class_.new(self, attribute, options_)
      end
    end

    def define_reader(attribute)
      define_method attribute do |locale: Mobility.locale, **options|
        return super() if options.delete(:super)
        Mobility.enforce_available_locales!(locale)
        mobility_backend_for(attribute).read(locale.to_sym, options)
      end

      define_method "#{attribute}?" do |locale: Mobility.locale, **options|
        return super() if options.delete(:super)
        Mobility.enforce_available_locales!(locale)
        mobility_backend_for(attribute).read(locale.to_sym, options).present?
      end
    end

    def define_writer(attribute)
      define_method "#{attribute}=" do |value, locale: Mobility.locale, **options|
        return super(value) if options.delete(:super)
        Mobility.enforce_available_locales!(locale)
        mobility_backend_for(attribute).write(locale.to_sym, value, options)
      end
    end

    def get_backend_class(backend)
      Module === backend ? backend : get_class_from_key(Mobility::Backends, backend)
    end

    def get_plugin_class(plugin)
      require "mobility/plugins/#{plugin}"
      get_class_from_key(Mobility::Plugins, plugin)
    end

    def get_class_from_key(parent_class, key)
      klass_name = key.to_s.gsub(/(^|_)(.)/){|x| x[-1..-1].upcase}
      parent_class.const_get(klass_name)
    end
  end
end
