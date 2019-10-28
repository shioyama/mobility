# frozen-string-literal: true

module Mobility
=begin

Defines convenience methods on plugin module to hook into initialize/included
method calls on +Mobility::Attributes+ instance.

- #initialize_hook: called after {{Mobility::Attributes#initialize}, with
  attribute names and options hash.
- #included_hook: called after {{Mobility::Attributes#included}, with included
  class (model class) and backend class. (Use this hook to include any
  module(s) into backend class.)

@example
  module MyPlugin
    extend Mobility::Plugin

    initialize_hook do |*names, **options|
      names.each do |name|
        define_method "#{name}_foo" do
          # method body
        end
      end
    end

    included_hook do |klass, backend_class|
      backend_class.include MyBackendMethods
      klass.include MyModelMethods
    end
  end

=end
  module Plugin
    def initialize_hook(&block)
      define_method :initialize do |*names, **options|
        super(*names, **options)
        class_exec(*names, **options, &block)
      end
    end

    def included_hook(&block)
      define_method :included do |klass|
        super(klass).tap do |backend_class|
          class_exec(klass, backend_class, &block)
        end
      end
    end
  end
end
