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

      # Backend class
      # @return [Class] Backend class
      attr_reader :backend_class

      # Name of backend
      # @return [Symbol,Class] Name of backend, or backend class
      attr_reader :backend_name

      initialize_hook do |*, backend:|
        @backend_name = backend
      end

      # Setup backend class, include modules into model class, include/extend
      # shared modules and setup model with backend setup block (see
      # {Mobility::Backend::Setup#setup_model}).
      def included(klass)
        super

        if backend_name
          @backend_class = Backends.load_backend(backend_name)
            .for(klass)
            .with_options(@options.merge(model_class: klass))

          klass.include InstanceMethods
          klass.extend ClassMethods

          backend_class.setup_model(klass, names)

          backend_class
        end
      end

      # Include backend name in inspect string.
      # @return [String]
      def inspect
        "#<Attributes (#{backend_name}) @names=#{names.join(", ")}>"
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
          @backends ||= BackendsCache.new(self)
          @backends[name.to_sym]
        end
      end

      class BackendsCache < ::Hash
        def initialize(klass)
          # Preload backend mapping
          klass.mobility_modules.each do |mod|
            mod.names.each { |name| self[name.to_sym] = mod.backend_class }
          end

          super() do |hash, name|
            if (mod = klass.mobility_modules.find { |m| m.names.include? name.to_s })
              hash[name] = mod.backend_class
            else
              raise KeyError, "No backend for: #{name}."
            end
          end
        end
      end
      private_constant :BackendsCache
    end

    register_plugin(:backend, Backend)
  end
end
