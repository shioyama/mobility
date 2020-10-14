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
    # Includes translated attributes on model class.
    # @!method translates(*attributes, **options)
    #   @param [Array<String>] attributes
    #   @param [Hash] options
    #   @yield Yields to block with backend as context
    def translates(*args, **options)
      include Mobility.config.translations_class.new(*args, **options)
    end
  end
end
