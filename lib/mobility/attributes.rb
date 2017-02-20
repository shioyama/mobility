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
      # Create a subclass of Mobility::Backend::MyBackend and include in it:
      # - Mobility::Cache (from the cache: true option)
      # - Mobility::Fallbacks (from the fallbacks: true option)
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
model class required by the backend, as happens in the {Backend::KeyValue} and
{Backend::Table} backends.

The +setup+ block is also used to extend the +i18n+ scope/dataset with
backend-specific query method support.

Since setup blocks are evaluated on the model class, it is possible that
backends can conflict (for example, overwriting previously defined methods).
Care should be taken to avoid defining methods on the model class, or where
necessary, ensure that names are defined in such a way as to avoid conflicts
with other backends.

=end
  class Attributes < Module
    # Attributes for which accessors will be defined
    # @return [Array<String>] Array of attributes
    attr_reader :attributes

    # Backend options
    # @return [Hash] Backend options
    attr_reader :options

    # Backend class
    # @return [Class] Backend class
    attr_reader :backend_class

    # Name of backend
    # @return [Symbol] Name of backend
    attr_reader :backend_name

    # @param [Symbol] method One of: [reader, writer, accessor]
    # @param [Array<String>] _attributes Attributes to define backend for
    # @param [Hash] _options Backend options hash
    # @option _options [Class] model_class Class of model
    # @option _options [Boolean, Array<Symbol>] locale_accessors Enable locale
    #   accessors or specify locales for which accessors should be defined on
    #   this model backend. Will default to +true+ if +dirty+ option is +true+.
    # @option _options [Boolean] cache (true) Enable cache for this model backend
    # @option _options [Boolean, Hash] fallbacks Enable fallbacks or specify fallbacks for this model backend
    # @option _options [Boolean] dirty Enable dirty tracking for this model backend
    # @raise [ArgumentError] if method is not reader, writer or accessor
    def initialize(method, *_attributes, **_options)
      raise ArgumentError, "method must be one of: reader, writer, accessor" unless %i[reader writer accessor].include?(method)
      @options = _options
      @attributes = _attributes.map &:to_s
      model_class = options[:model_class]
      @backend_name = options.delete(:backend) || Mobility.config.default_backend
      @backend_class = Class.new(get_backend_class(backend:     @backend_name,
                                                   model_class: model_class))

      options[:locale_accessors] ||= true if options[:dirty]

      @backend_class.configure!(options) if @backend_class.respond_to?(:configure!)

      @backend_class.include Backend::Cache unless options[:cache] == false
      @backend_class.include Backend::Dirty.for(model_class) if options[:dirty]
      @backend_class.include Backend::Fallbacks if options[:fallbacks]
      @accessor_locales = options[:locale_accessors]
      @accessor_locales = Mobility.config.default_accessor_locales if options[:locale_accessors] == true

      attributes.each do |attribute|
        define_backend(attribute)

        if %i[accessor reader].include?(method)
          define_method attribute do |**options|
            mobility_get(attribute, options)
          end

          define_method "#{attribute}?" do |**options|
            mobility_present?(attribute, options)
          end
        end

        define_method "#{attribute}=" do |value|
          mobility_set(attribute, value)
        end if %i[accessor writer].include?(method)

        define_locale_accessors(attribute, @accessor_locales) if @accessor_locales
      end
    end

    # Add this attributes module to shared {Mobility::Wrapper} and setup model
    # with backend setup block (see {Mobility::Backend::Setup#setup_model}).
    # @param model_class [Class] Class of model
    def included(model_class)
      model_class.mobility << self
      backend_class.setup_model(model_class, attributes, options)
    end

    # Yield each attribute to block
    # @yield [String] Attribute
    def each &block
      attributes.each &block
    end

    private

    def define_backend(attribute)
      _backend_class, _options = backend_class, options
      define_method Backend.method_name(attribute) do
        @mobility_backends ||= {}
        @mobility_backends[attribute] ||= _backend_class.new(self, attribute, _options)
      end
    end

    def define_locale_accessors(attribute, locales)
      locales.each do |locale|
        normalized_locale = Mobility.normalize_locale(locale)
        define_method "#{attribute}_#{normalized_locale}" do |**options|
          mobility_get(attribute, options.merge(locale: locale))
        end
        define_method "#{attribute}_#{normalized_locale}?" do |**options|
          mobility_present?(attribute, options.merge(locale: locale))
        end
        define_method "#{attribute}_#{normalized_locale}=" do |value, **options|
          mobility_set(attribute, value, locale: locale)
        end
      end
    end

    def get_backend_class(backend: nil, model_class: nil)
      raise Mobility::BackendRequired, "Backend option required if Mobility.config.default_backend is not set." if backend.nil?
      klass = Module === backend ? backend : Mobility::Backend.const_get(backend.to_s.camelize.gsub(/\s+/, ''))
      model_class.nil? ? klass : klass.for(model_class)
    end
  end
end
