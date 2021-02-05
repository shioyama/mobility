# frozen-string-literal: true
module Mobility
  module Plugins
=begin

Plugin for setting up a backend for a set of model attributes. All backend
plugins must depend on this.

Defines:
- instance method +mobility_backends+ which returns a hash whose keys are
  attribute names and values a backend for each attribute.
- class method +mobility_backend_class+ which takes an attribute name and
  returns the backend class for that name.

=end
    module Backend
      extend Plugin

      requires :attributes, include: :before

      # Backend class
      # @return [Class] Backend class
      attr_reader :backend_class

      # Backend
      # @return [Symbol,Class,Class] Name of backend, or backend class
      attr_reader :backend

      # Backend options
      # @return [Hash] Options for backend
      attr_reader :backend_options

      def initialize(*args, **original_options)
        super

        include InstanceMethods
      end

      # Setup backend class, include modules into model class, include/extend
      # shared modules and setup model with backend setup block (see
      # {Mobility::Backend::Setup#setup_model}).
      def included(klass)
        super

        klass.extend ClassMethods

        if backend
          @backend_class = backend.build_subclass(klass, backend_options)

          backend_class.setup_model(klass, names)

          names = @names
          backend_class = @backend_class

          klass.class_eval do
            names.each { |name| mobility_backend_classes[name.to_sym] = backend_class }
          end

          backend_class
        end
      end

      # Include backend name in inspect string.
      # @return [String]
      def inspect
        "#<Translations (#{backend}) @names=#{names.join(", ")}>"
      end

      def load_backend(backend)
        Backends.load_backend(backend)
      rescue Backends::LoadError => e
        raise e, "could not find a #{backend} backend. Did you forget to include an ORM plugin like active_record or sequel?"
      end

      private

      # Override to extract backend options from options hash.
      def initialize_options(original_options)
        super

        case options[:backend]
        when String, Symbol, Class
          @backend, @backend_options = options[:backend], options.dup
        when Array
          @backend, @backend_options = options[:backend]
          @backend_options = @backend_options.merge(options)
        when NilClass
          @backend = @backend_options = nil
        else
          raise ArgumentError, "backend must be either a backend name, a backend class, or a two-element array"
        end

        @backend = load_backend(backend)
      end

      # Override default validation to exclude backend options, which may be
      # mixed in with plugin options.
      def validate_options(options)
        return super unless backend
        super(options.slice(*(options.keys - backend.valid_keys)))

        # Validate that the default backend from config has valid keys, or if
        # it is overridden by an array input that the array has valid keys.
        if options[:backend].is_a?(Array)
          name, backend_options = options[:backend]
          extra_keys = backend_options.keys - backend.valid_keys
          raise InvalidOptionKey, "These are not valid #{name} backend keys: #{extra_keys.join(', ')}." unless extra_keys.empty?
        end
      end

      # Override default argument-handling in DSL to store kwargs passed along
      # with plugin name.
      def self.configure_default(defaults, key, backend = nil, backend_options = {})
        defaults[key] = [backend, backend_options] if backend
      end

      class MobilityBackends < Hash
        def initialize(model)
          @model = model
          super()
        end

        def [](name)
          return fetch(name) if has_key?(name)
          return self[name.to_sym] if String === name
          self[name] = @model.class.mobility_backend_class(name).new(@model, name.to_s)
        end
      end

      module InstanceMethods
        # Return a new backend for an attribute name.
        # @return [Hash] Hash of attribute names and backend instances
        # @api private
        def mobility_backends
          @mobility_backends ||= MobilityBackends.new(self)
        end

        def initialize_dup(other)
          @mobility_backends = nil
          super
        end
      end

      module ClassMethods
        # Return backend class for a given attribute name.
        # @param [Symbol,String] Name of attribute
        # @return [Class] Backend class
        def mobility_backend_class(name)
          mobility_backend_classes.fetch(name.to_sym)
        rescue KeyError
          raise KeyError, "No backend for: #{name}"
        end

        def inherited(klass)
          parent_classes = mobility_backend_classes.freeze # ensure backend classes are not modified after being inherited
          klass.class_eval { @mobility_backend_classes = parent_classes.dup }
          super
        end

        protected

        def mobility_backend_classes
          @mobility_backend_classes ||= {}
        end
      end

      class InvalidOptionKey < Error; end
    end

    register_plugin(:backend, Backend)
  end
end
