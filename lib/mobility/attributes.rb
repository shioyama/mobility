module Mobility
  class Attributes < Module
    attr_reader :attributes, :options, :backend_class

    def initialize(method, *_attributes)
      raise ArgumentError, "method must be one of: reader, writer, accessor" unless %i[reader writer accessor].include?(method)
      @options = _attributes.extract_options!.with_indifferent_access
      @attributes = _attributes.map &:to_s
      @backend_class = Class.new(get_backend_class(options.delete(:backend)))

      @backend_class.configure!(options) if @backend_class.respond_to?(:configure!)

      @backend_class.include Backend::Cache unless options[:cache] == false
      @backend_class.include Backend::Fallbacks if options[:fallbacks]

      attributes.each do |attribute|
        define_backend(attribute)

        define_method attribute do
          send("#{attribute}_translations").read(Mobility.locale).to_s.presence
        end if %i[accessor reader].include?(method)

        define_method "#{attribute}=" do |value|
          send("#{attribute}_translations").write(Mobility.locale, value.presence)
        end if %i[accessor writer].include?(method)
      end
    end

    def included(model_class)
      backend_class.setup_model(model_class, attributes, options)
    end

    private

    def define_backend(attribute)
      _backend_class, _options = backend_class, options
      define_method "#{attribute}_translations" do
        @mobility_backends ||= {}
        @mobility_backends[attribute] ||= _backend_class.new(self, attribute, _options)
      end
    end

    def get_backend_class(object)
      object ||= Mobility.config.default_backend
      raise Mobility::BackendRequired, "Backend option required if Mobility.config.default_backend is not set." if object.nil?
      Module === object ? object : Mobility::Backend.const_get(object.to_s.titleize.camelize.gsub(/\s+/, ''))
    end
  end
end
