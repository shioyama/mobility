# frozen-string-literal: true

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
- implement a +configure!+ class method to apply any normalization to the
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

    def self.configure!(options)
      # ...
    end

    setup do |attributes, options|
      # Do something with attributes and options in context of model class.
    end
  end

@see Mobility::Attributes

=end

  module Backend
    autoload :ActiveModel,  'mobility/backend/active_model'
    autoload :ActiveRecord, 'mobility/backend/active_record'
    autoload :Cache,        'mobility/backend/cache'
    autoload :Column,       'mobility/backend/column'
    autoload :Dirty,        'mobility/backend/dirty'
    autoload :Fallbacks,    'mobility/backend/fallbacks'
    autoload :Hstore,       'mobility/backend/hstore'
    autoload :Jsonb,        'mobility/backend/jsonb'
    autoload :KeyValue,     'mobility/backend/key_value'
    autoload :Null,         'mobility/backend/null'
    autoload :OrmDelegator, 'mobility/backend/orm_delegator'
    autoload :Sequel,       'mobility/backend/sequel'
    autoload :Serialized,   'mobility/backend/serialized'
    autoload :Table,        'mobility/backend/table'

    # @return [String] Backend attribute
    attr_reader :attribute

    # @return [Object] Model on which backend is defined
    attr_reader :model

    # @return [Hash] Backend options
    attr_reader :options

    # @!macro [new] backend_constructor
    #   @param model Model on which backend is defined
    #   @param [String] attribute Backend attribute
    #   @option options [Hash] fallbacks Fallbacks hash
    def initialize(model, attribute, **options)
      @model = model
      @attribute = attribute
      @options = options
      fallbacks = options[:fallbacks]
      @fallbacks = I18n::Locale::Fallbacks.new(fallbacks) if fallbacks.is_a?(Hash)
    end

    # @!macro [new] backend_reader
    #   @param [Symbol] locale Locale to read
    #   @param [Hash] options
    #   @return [Object] Value of translation
    #
    # @!macro [new] backend_writer
    #   @param [Symbol] locale Locale to write
    #   @param [Object] value Value to write
    #   @param [Hash] options
    #   @return [Object] Updated value

    # Extend included class with +setup+ method
    def self.included(base)
      base.extend(Setup)
    end

    # @param [String] attribute
    # @return [String] name of backend reader method
    def self.method_name(attribute)
      "#{attribute}_backend".freeze
    end

    # Defines setup hooks for backend to customize model class.
    module Setup
      # Assign block to be called on model class.
      # @yield [attributes, options]
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
      # @param [Array<String>] attributes
      # @param [Hash] options
      def setup_model(model_class, attributes, **options)
        return unless setup_block = @setup_block
        model_class.class_exec(attributes, options, &setup_block)
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
    end
  end
end
