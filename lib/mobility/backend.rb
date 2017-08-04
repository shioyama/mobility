# frozen-string-literal: true
require "mobility/backend/orm_delegator"

module Mobility
=begin

Defines a minimum set of shared components included in any backend. These are:

- a reader returning the +model+ on which the backend is defined ({#model})
- a reader returning the +attribute+ for which the backend is defined
  ({#attribute})
- a reader returning +options+ configuring the backend ({#options})
- a constructor setting these three elements (+model+, +attribute+, +options+),
  and extracting fallbacks from the options hash ({#initialize})
- a +setup+ method adding any configuration code to the model class
  ({Setup#setup})

On top of this, a backend will normally:

- implement a +read+ instance method to read from the backend
- implement a +write+ instance method to write to the backend
- implement a +configure+ class method to apply any normalization to the
  options hash
- call the +setup+ method yielding attributes and options to configure the
  model class

@example Defining a Backend
  class MyBackend
    include Mobility::Backend

    def read(locale, **options)
      # ...
    end

    def write(locale, value, **options)
      # ...
    end

    def self.configure(options)
      # ...
    end

    setup do |attributes, options|
      # Do something with attributes and options in context of model class.
    end
  end

@see Mobility::Attributes

=end

  module Backend
    # @return [String] Backend attribute
    attr_reader :attribute

    # @return [Object] Model on which backend is defined
    attr_reader :model

    # @!macro [new] backend_constructor
    #   @param model Model on which backend is defined
    #   @param [String] attribute Backend attribute
    def initialize(model, attribute, **_)
      @model = model
      @attribute = attribute
    end

    # @!macro [new] backend_reader
    #   @param [Symbol] locale Locale to read
    #   @return [Object] Value of translation
    #
    # @!macro [new] backend_writer
    #   @param [Symbol] locale Locale to write
    #   @param [Object] value Value to write
    #   @return [Object] Updated value

    # Extend included class with +setup+ method
    def self.included(base)
      base.extend(Setup)
    end

    # @param [String] attribute
    # @return [String] name of backend reader method
    def self.method_name(attribute)
      @backend_method_names ||= {}
      @backend_method_names[attribute] ||= "#{attribute}_backend".freeze
    end

    # Defines setup hooks for backend to customize model class.
    module Setup
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
      end

      # Call setup block on a class with attributes and options.
      # @param model_class Class to be setup-ed
      # @param [Array<String>] attribute_names
      # @param [Hash] options
      def setup_model(model_class, attribute_names, **options)
        return unless setup_block = @setup_block
        model_class.class_exec(attribute_names, options, &setup_block)
      end

      # {Attributes} uses this method to get a backend class specific to the
      # model using the backend. Backend classes can override this method to
      # return a class specific to the model class using the backend (e.g.
      # either an ActiveRecord or Sequel backend class depending on whether the
      # model is an ActiveRecord model or a Sequel model.)
      # @see OrmDelegator
      # @see Attributes
      # @return [self] returns itself
      def for(_)
        self
      end

      # Called from plugins to apply custom processing for this backend.
      # Name is the name of the plugin.
      # @param [Symbol] name Name of plugin
      # @return [Boolean] Whether the plugin was applied
      # @note This is currently only called by Plugins::Cache.
      def apply_plugin(_)
        false
      end
    end
  end
end
