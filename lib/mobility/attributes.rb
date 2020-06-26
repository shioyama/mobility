# frozen_string_literal: true
require "mobility/util"
require "tsort"

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
    class << self
      def plugin(name, **options)
        Plugin.configure(self, defaults) { __send__ name, **options }
      end

      def plugins(&block)
        Plugin.configure(self, defaults, &block)
      end

      def defaults
        @defaults ||= {}
      end
    end

    # Attribute names for which accessors will be defined
    # @return [Array<String>] Array of names
    attr_reader :names

    # @param [Array<String>] attribute_names Names of attributes to define backend for
    # @param [Hash] options Backend options hash
    def initialize(*attribute_names, **options)
      @options = self.class.defaults.merge(options)
      @names = attribute_names.map(&:to_s).freeze
    end

    def included(klass)
      klass.extend ClassMethods
      nil
    end

    # Yield each attribute name to block
    # @yieldparam [String] Attribute
    def each &block
      names.each(&block)
    end

    # Show useful information about this module.
    # @return [String]
    def inspect
      "#<Attributes @names=#{names.join(", ")}>"
    end

    module ClassMethods
      # Return all {Mobility::Attributes} module instances from among ancestors
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
    end
  end
end
