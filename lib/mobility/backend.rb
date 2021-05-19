# frozen-string-literal: true
require 'digest/md5'

module Mobility
=begin

Defines a minimum set of shared components included in any backend. These are:

- a reader returning the +model+ on which the backend is defined ({#model})
- a reader returning the +attribute+ for which the backend is defined
  ({#attribute})
- a constructor setting these two elements (+model+, +attribute+)
- a +setup+ method adding any configuration code to the model class
  ({ClassMethods#setup})

On top of this, a backend will normally:

- implement a +read+ instance method to read from the backend
- implement a +write+ instance method to write to the backend
- implement an +each_locale+ instance method to iterate through available locales
  (used to define other +Enumerable+ traversal and search methods)
- implement a +valid_keys+ class method returning an array of symbols
  corresponding to valid keys for configuring this backend.
- implement a +configure+ class method to apply any normalization to the
  keys on the options hash included in +valid_keys+
- call the +setup+ method yielding attributes and options to configure the
  model class

@example Defining a Backend
  class MyBackend
    include Mobility::Backend

    def read(locale, options = {})
      # ...
    end

    def write(locale, value, options = {})
      # ...
    end

    def each_locale
      # ...
    end

    def self.configure(options)
      # ...
    end

    setup do |attributes, options|
      # Do something with attributes and options in context of model class.
    end
  end

@see Mobility::Translations

=end

  module Backend
    include Enumerable

    # @return [String] Backend attribute
    attr_reader :attribute

    # @return [Object] Model on which backend is defined
    attr_reader :model

    # @!macro [new] backend_constructor
    #   @param model Model on which backend is defined
    #   @param [String] attribute Backend attribute
    def initialize(*args)
      @model = args[0]
      @attribute = args[1]
    end

    def ==(backend)
      backend.class == self.class &&
        backend.attribute == attribute &&
        backend.model == model
    end

    # @!macro [new] backend_reader
    #   Gets the translated value for provided locale from configured backend.
    #   @param [Symbol] locale Locale to read
    #   @return [Object] Value of translation
    #
    # @!macro [new] backend_writer
    #   Updates translation for provided locale without calling backend's methods to persist the changes.
    #   @param [Symbol] locale Locale to write
    #   @param [Object] value Value to write
    #   @return [Object] Updated value

    # @!macro [new] backend_iterator
    #   Yields locales available for this attribute.
    #   @yieldparam [Symbol] Locale
    def each_locale
    end

    # Yields translations to block
    # @yieldparam [Mobility::Backend::Translation] Translation
    def each
      each_locale { |locale| yield Translation.new(self, locale) }
    end

    # List locales available for this backend.
    # @return [Array<Symbol>] Array of available locales
    def locales
      map(&:locale)
    end

    # @param [Symbol] locale Locale to read
    # @return [TrueClass,FalseClass] Whether translation is present for locale
    def present?(locale, options = {})
      Util.present?(read(locale, **options))
    end

    # @!method model_class
    #   Returns name of model in which backend is used.
    #   @return [Class] Model class

    # @return [Hash] options
    def options
      self.class.options
    end

    # Extend included class with +setup+ method and other class methods
    def self.included(base)
      base.extend ClassMethods
      base.singleton_class.class_eval do
        attr_accessor :options, :model_class
        protected :options=, :model_class=
      end
    end

    # Defines setup hooks for backend to customize model class.
    module ClassMethods
      # Returns valid option keys for this backend. This is overriden in
      # backends to define which keys are valid for each backend class.
      # @return [Array]
      def valid_keys
        []
      end

      # Assign block to be called on model class.
      # @yield [attribute_names, options]
      # @note When called multiple times, setup blocks will be appended
      #   so that they are run together consecutively on class.
      def setup &block
        if @setup_block
          setup_block = @setup_block
          @setup_block = lambda do |*args|
            class_exec(*args, &setup_block)
            class_exec(*args, &block)
          end
        else
          @setup_block = block
        end
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@setup_block, @setup_block)
        subclass.instance_variable_set(:@options, @options)
        subclass.instance_variable_set(:@model_class, @model_class)
      end

      # Call setup block on a class with attributes and options.
      # @param model_class Class to be setup-ed
      # @param [Array<String>] attribute_names
      # @param [Hash] options
      def setup_model(model_class, attribute_names)
        return unless setup_block = @setup_block
        model_class.class_exec(attribute_names, options, &setup_block)
      end

      # Build a subclass of this backend class for a given set of options
      # @note This method also freezes the options hash to prevent it from
      #   being changed.
      # @param [Class] model_class Class
      # @param [Hash] options
      # @return [Class] backend subclass
      def build_subclass(model_class, options)
        Class.new(self).tap do |klass|
          klass.model_class = model_class
          klass.configure(options) if klass.respond_to?(:configure)
          klass.options = options.freeze

          subclass_name = SubclassNameGenerator.call(model_class, self, options)
          if subclass_name && !Object.const_defined?(subclass_name)
            Object.const_set(subclass_name, klass)
          end
        end
      end

      # Create instance and class methods to access value on options hash
      # @param [Symbol] name Name of option reader
      def option_reader(name)
        module_eval <<-EOM, __FILE__, __LINE__ + 1
        def self.#{name}
          options[:#{name}]
        end

        def #{name}
          self.class.options[:#{name}]
        end
        EOM
      end

      # Show useful information about this backend class, if it has no name.
      # @return [String]
      def inspect
        name ? super : "#<#{superclass.name}>"
      end
    end

    Translation = Struct.new(:backend, :locale) do
      def read(options = {})
        backend.read(locale, options)
      end

      def write(value, options = {})
        backend.write(locale, value, options)
      end
    end

    module SubclassNameGenerator
      def self.call(model_class, backend_class, options)
        # If the model class and backend have names, we give the backend subclass a name
        if model_class.name && backend_class.name
          class_name_str = model_class.name.gsub('::', '_')
          backend_name_str = backend_class.name.gsub('::', '_')
          options_str = ::Digest::MD5.hexdigest(options.sort.inspect)[0..5]
          [class_name_str, backend_name_str, options_str].join('__')
        end
      end
    end
  end
end
