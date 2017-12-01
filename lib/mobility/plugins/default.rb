module Mobility
  module Plugins
=begin

Defines value or proc to fall through to if return value from getter would
otherwise be nil.

If default is a proc, it is passed a hash with four keyword arguments:
- +model+: the model instance
- +attribute+: the attribute name (a String)
- +locale+: the locale (a Symbol)
- +options+: hash of options passed in to accessor

@example With default enabled (falls through to default value)
  class Post
    extend Mobility
    translates :title, default: 'foo'
  end

  Mobility.locale = :en
  post = Post.new(title: "English title")

  Mobility.locale = :de
  post.title
  #=> 'foo'

@example Overriding default with reader option
  class Post
    extend Mobility
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
    extend Mobility
    translates :title, default: lambda { |attribute:, locale:| "#{attribute} in #{locale}" }
  end

  Mobility.locale = :en
  post = Post.new(title: nil)
  post.title
  #=> "title in en"

  post.title(default: lambda { |model:| model.class.name.to_s })
  #=> "Post"
=end
    class Default < Module
      # Applies default plugin to attributes.
      # @param [Attributes] attributes
      # @param [Object] option
      def self.apply(attributes, option)
        attributes.backend_class.include(new(option))
      end

      def initialize(default_option)
        define_method :read do |locale, options = {}|
          default = options.has_key?(:default) ? options.delete(:default) : default_option
          if (value = super(locale, options)).nil?
            return default unless default.is_a?(Proc)
            default.call(model: model,
                         attribute: attribute,
                         locale: locale,
                         options: options)
          else
            value
          end
        end
      end
    end
  end
end
