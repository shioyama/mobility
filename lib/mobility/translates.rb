# frozen_string_literal: true

module Mobility
=begin

Defines methods for attaching backends to a class. A block can optionally be
passed to accessors to configure backend (see example below).

@example Defining backend on a class
  class MyClass
    extend Translates
    mobility_accessor :foo, option: :value
  end

@example Passing backend to a block
  class MyClass
    extend Translates
    mobility_accessor :foo, option: :value do
      # add custom code to backend class for this attribute only
    end
  end

@example Defining only a backend reader and presence method
  class MyClass
    extend Translates
    mobility_reader :foo
  end

  instance = MyClass.new
  instance.foo         #=> (some value)
  instance.foo?        #=> true
  instance.foo = "foo" #=> NoMethodError

@example Defining only a backend writer
  class MyClass
    extend Translates
    mobility_writer :foo
  end

  instance = MyClass.new
  instance.foo         #=> NoMethodError
  instance.foo?        #=> NoMethodError
  instance.foo = "foo" #=> (sets attribute to value "foo")
=end
  module Translates
    # Defines mobility accessor on model class.
    # @!method mobility_accessor(*attributes, **options)
    #   @param [Array<String>] attributes
    #   @param [Hash] options
    #   @yield Yields to block with backend as context

    # Defines mobility reader and presence method on model class.
    # @!method mobility_reader(*attributes, **options)
    #   @param [Array<String>] attributes
    #   @param [Hash] options
    #   @yield Yields to block with backend as context

    # Defines mobility writer on model class.
    # @!method mobility_writer(*attributes, **options)
    #   @param [Array<String>] attributes
    #   @param [Hash] options
    #   @yield Yields to block with backend as context
    %w[accessor reader writer].each do |method|
      class_eval <<-EOM, __FILE__, __LINE__ + 1
        def mobility_#{method}(*args, **options, &block)
          attributes = Attributes.new(*args, method: :#{method}, **options)
          attributes.backend.instance_eval(&block) if block_given?
          include attributes
        end
      EOM
    end
  end
end
