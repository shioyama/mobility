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

      depends_on :attributes, include: :before

      # Backend class
      # @return [Class] Backend class
      attr_reader :backend_class

      # Name of backend
      # @return [Symbol,Class] Name of backend, or backend class
      attr_reader :backend_name

      initialize_hook do
        @backend_name = options[:backend]
      end

      # Setup backend class, include modules into model class, include/extend
      # shared modules and setup model with backend setup block (see
      # {Mobility::Backend::Setup#setup_model}).
      def included(klass)
        super

        if backend_name
          @backend_class = load_backend(backend_name)
            .with_options(@options.merge(model_class: klass))

          klass.include InstanceMethods
          klass.extend ClassMethods

          backend_class.setup_model(klass, names)

          @names.each do |name|
            klass.register_mobility_backend_class(name, @backend_class)
          end

          backend_class
        end
      end

      # Include backend name in inspect string.
      # @return [String]
      def inspect
        "#<Attributes (#{backend_name}) @names=#{names.join(", ")}>"
      end

      def load_backend(backend)
        Backends.load_backend(backend)
      end

      module InstanceMethods
        # Return a new backend for an attribute name.
        # @return [Hash] Hash of attribute names and backend instances
        # @api private
        def mobility_backends
          @mobility_backends ||= ::Hash.new do |hash, name|
            next hash[name.to_sym] if String === name
            hash[name] = self.class.mobility_backend_class(name).new(self, name.to_s)
          end
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

        def register_mobility_backend_class(name, backend_class)
          mobility_backend_classes[name.to_sym] = backend_class
        end

        def inherited(klass)
          klass.mobility_backend_classes.merge!(@mobility_backend_classes)
          super
        end

        protected

        def mobility_backend_classes
          @mobility_backend_classes ||= {}
        end
      end
    end

    register_plugin(:backend, Backend)
  end
end
