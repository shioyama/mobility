module Mobility
  class Attributes < Module
    attr_reader :attributes, :options, :backend_class

    def initialize(method, *_attributes)
      raise ArgumentError, "method must be one of: reader, writer, accessor" unless %i[reader writer accessor].include?(method)
      @options = _attributes.extract_options!.with_indifferent_access
      @attributes = _attributes.map &:to_s
      @backend_class = Class.new(get_backend_class(options.delete(:backend)))

      options[:locale_accessors] ||= true if options[:dirty]

      @backend_class.configure!(options) if @backend_class.respond_to?(:configure!)

      @backend_class.include Backend::Cache unless options[:cache] == false
      @backend_class.include Backend::Dirty if options[:dirty]
      @backend_class.include Backend::Fallbacks if options[:fallbacks]
      @accessor_locales = options[:locale_accessors]
      @accessor_locales = Mobility.config.default_accessor_locales if options[:locale_accessors] == true

      attributes.each do |attribute|
        define_backend(attribute)

        define_method attribute do |options={}|
          mobility_get(attribute, options)
        end if %i[accessor reader].include?(method)

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
        define_method "#{attribute}_#{normalized_locale}" do |options={}|
          mobility_get(attribute, options.with_indifferent_access.merge(locale: locale))
        end
        define_method "#{attribute}_#{normalized_locale}=" do |value, options={}|
          mobility_set(attribute, value, locale: locale)
        end
      end
    end

    def get_backend_class(object)
      object ||= Mobility.config.default_backend
      raise Mobility::BackendRequired, "Backend option required if Mobility.config.default_backend is not set." if object.nil?
      Module === object ? object : Mobility::Backend.const_get(object.to_s.titleize.camelize.gsub(/\s+/, ''))
    end
  end
end
