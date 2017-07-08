module Mobility
  module Backend
=begin

Defines value or proc to fall through to if return value from getter would
otherwise be nil.

@example With default enabled (falls through to default value)
  class Post
    translates :title, default: 'foo'
  end

  Mobility.locale = :en
  post = Post.new(title: "English title")

  Mobility.locale = :de
  post.title
  #=> 'foo'

@example Overriding default with reader option
  class Post
    translates :title, default: 'foo'
  end

  Mobility.locale = :en
  post  = Post.new(title: "English title")

  Mobility.locale = :de
  post.title
  #=> 'foo'

  post.title(default: 'bar')
  #=> 'bar'

  post.title(default: nil)
  #=> nil

@example Using Proc as default
  class Post
    translates :title, default: lambda { |model:, attribute:| attribute.to_s }
  end

  post = Post.new(title: nil)
  post.title
  #=> "title"

  post.title(default: lambda { |model:| model.class.name.to_s }
  #=> "Post"
=end
    module Default
      # @param [Class] backend_class
      # @param [Boolean] _value
      # @param [Hash] options
      def self.apply(backend_class, _value, **options)
        backend_class.include(self) if options.has_key?(:default)
      end

      # @!macro [new] backend_constructor
      #   @option backend_options [Object] default Default value
      def initialize(*args, **backend_options)
        super
        @default = backend_options[:default]
      end

      # @group Backend Accessors
      # @!macro backend_reader
      # @param [Boolean] default
      #   *false* to disable default value, or another value to set default for
      #   this read.
      def read(locale, **options)
        default = options.has_key?(:default) ? options.delete(:default) : @default
        if (value = super).nil?
          default.is_a?(Proc) ? default.call(model: model, attribute:attribute) : default
        else
          value
        end
      end
    end
  end
end
