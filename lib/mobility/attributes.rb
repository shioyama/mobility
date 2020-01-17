# frozen_string_literal: true
require "mobility/util"

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

  Attributes.new("title", backend: :my_backend, locale_accessors: [:en, :ja], cache: true, fallbacks: true)

will generate an anonymous module that behaves approximately like this:

  Module.new do
    def mobility_backends
      # Returns a memoized hash with attribute name keys and backend instance
      # values.  When a key is fetched from the hash, the hash calls
      # +self.class.mobility_backend_class(name)+ (where +name+ is the
      # attribute name) to get the backend class, then instantiate it (passing
      # the model instance and attribute name to its initializer) and return it.
      #
      # The backend class returned from the class method
      # +mobility_backend_class+ returns a subclass of
      # +Mobility::Backends::MyBackend+ and includes into it:
      #
      # - Mobility::Plugins::Cache (from the +cache: true+ option)
      # - instance of Mobility::Plugins::Fallbacks (from the +fallbacks: true+ option)
      # - Mobility::Plugins::Presence (by default, disabled by +presence: false+)
    end

    def title(locale: Mobility.locale)
      mobility_backends[:title].read(locale)
    end

    def title?(locale: Mobility.locale)
      mobility_backends[:title].read(locale).present?
    end

    def title=(value, locale: Mobility.locale)
      mobility_backends[:title].write(locale, value)
    end

    # Start Locale Accessors
    #
    def title_en
      title(locale: :en)
    end

    def title_en?
      title?(locale: :en)
    end

    def title_en=(value)
      public_send(:title=, value, locale: :en)
    end

    def title_ja
      title(locale: :ja)
    end

    def title_ja?
      title?(locale: :ja)
    end

    def title_ja=(value)
      public_send(:title=, value, locale: :ja)
    end
    # End Locale Accessors
  end

Including this module into a model class will thus add the backend method, the
reader, writer and presence methods, and the locale accessor so the model
class. (These methods are in fact added to the model in an +included+ hook.)

Note that some simplifications have been made above for readability. (In
reality, all getters and setters accept an options hash which is passed along
to the backend instance.)

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

Since setup blocks are evaluated on the model class, it is possible that
backends can conflict (for example, overwriting previously defined methods).
Care should be taken to avoid defining methods on the model class, or where
necessary, ensure that names are defined in such a way as to avoid conflicts
with other backends.

=end
  class Attributes < Module
    def self.plugin(name)
      include Plugins.load_plugin(name)
    end

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

    # @param [Array<String>] attribute_names Names of attributes to define backend for
    # @param [Symbol] method One of: [reader, writer, accessor]
    # @param [Symbol,Class] backend Backend to use
    # @param [Hash] backend_options Backend options hash
    # @raise [ArgumentError] if method is not reader, writer or accessor
    def initialize(*attribute_names, method: :accessor, backend: Mobility.default_backend, **backend_options)
      raise ArgumentError, "method must be one of: reader, writer, accessor" unless %i[reader writer accessor].include?(method)
      @options = Mobility.default_options.to_h.merge(backend_options)
      @names = attribute_names.map(&:to_s).freeze
      raise BackendRequired, "Backend option required if Mobility.config.default_backend is not set." if backend.nil?
      @backend_name = backend

      attribute_names.each do |name|
        define_backend(name)
        define_reader(name) if %i[accessor reader].include?(method)
        define_writer(name) if %i[accessor writer].include?(method)
      end
    end

    # Setup backend class, include modules into model class, include/extend
    # shared modules and setup model with backend setup block (see
    # {Mobility::Backend::Setup#setup_model}).
    # @param klass [Class] Class of model
    def included(klass)
      @backend_class = Backends.load_backend(backend_name)
        .for(klass)
        .with_options(options.merge(model_class: klass))

      klass.include InstanceMethods
      klass.extend ClassMethods

      backend_class.setup_model(klass, names)

      backend_class
    end

    # Yield each attribute name to block
    # @yieldparam [String] Attribute
    def each &block
      names.each(&block)
    end

    # Show useful information about this module.
    # @return [String]
    def inspect
      "#<Attributes (#{backend_name}) @names=#{names.join(", ")}>"
    end

    private

    def define_backend(attribute)
      module_eval <<-EOM, __FILE__, __LINE__ + 1
      def #{Backend.method_name(attribute)}
        mobility_backends[:#{attribute}]
      end
      EOM
    end

    def define_reader(attribute)
      class_eval <<-EOM, __FILE__, __LINE__ + 1
        def #{attribute}(**options)
          return super() if options.delete(:super)
          #{set_locale_from_options_inline}
          mobility_backends[:#{attribute}].read(locale, **options)
        end

        def #{attribute}?(**options)
          return super() if options.delete(:super)
          #{set_locale_from_options_inline}
          mobility_backends[:#{attribute}].present?(locale, **options)
        end
      EOM
    end

    def define_writer(attribute)
      class_eval <<-EOM, __FILE__, __LINE__ + 1
        def #{attribute}=(value, **options)
          return super(value) if options.delete(:super)
          #{set_locale_from_options_inline}
          mobility_backends[:#{attribute}].write(locale, value, **options)
        end
      EOM
    end

    # This string is evaluated inline in order to optimize performance of
    # getters and setters, avoiding extra steps where they are unneeded.
    def set_locale_from_options_inline
      <<-EOL
if options[:locale]
  #{"Mobility.enforce_available_locales!(options[:locale])" if I18n.enforce_available_locales}
  locale = options[:locale].to_sym
  options[:locale] &&= !!locale
else
  locale = Mobility.locale
end
EOL
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
      # Return all {Mobility::Attribute} module instances from among ancestors
      # of this model.
      # @return [Array<Mobility::Attributes>] Attribute modules
      def mobility_modules
        ancestors.grep(Attributes)
      end

      # Return translated attribute names on this model.
      # @return [Array<String>] Attribute names
      def mobility_attributes
        mobility_modules.map(&:names).flatten.uniq
      end

      # Return true if attribute name is translated on this model.
      # @param [String, Symbol] Attribute name
      # @return [Boolean]
      def mobility_attribute?(name)
        mobility_attributes.include?(name.to_s)
      end

      # @!method translated_attribute_names
      # @return (see #mobility_attributes)
      alias translated_attribute_names mobility_attributes

      # Return backend class for a given attribute name.
      # @param [Symbol,String] Name of attribute
      # @return [Class] Backend class
      def mobility_backend_class(name)
        @backends ||= BackendsCache.new(self)
        @backends[name.to_sym]
      end

      class BackendsCache < ::Hash
        def initialize(klass)
          # Preload backend mapping
          klass.mobility_modules.each do |mod|
            mod.names.each { |name| self[name.to_sym] = mod.backend_class }
          end

          super() do |hash, name|
            if mod = klass.mobility_modules.find { |m| m.names.include? name.to_s }
              hash[name] = mod.backend_class
            else
              raise KeyError, "No backend for: #{name}."
            end
          end
        end
      end
      private_constant :BackendsCache
    end
  end

  class BackendRequired < ArgumentError; end
end
