module Mobility
  class Attributes < Module
    attr_reader :attributes, :options, :backend_class, :backend_name

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

    def included(model_class)
      model_class.mobility << self
      backend_class.setup_model(model_class, attributes, options)
    end

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
