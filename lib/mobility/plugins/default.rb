module Mobility
  module Plugins
=begin

Defines value or proc to fall through to if return value from getter would
otherwise be nil.

If default is a +Proc+, it will be called with the context of the model, and
passed arguments:
- the attribute name (a String)
- the locale (a Symbol)
- hash of options passed in to accessor
The proc can accept zero to three arguments (see examples below)

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
    translates :title, default: lambda { |attribute, locale| "#{attribute} in #{locale}" }
  end

  Mobility.locale = :en
  post = Post.new(title: nil)
  post.title
  #=> "title in en"

  post.title(default: lambda { self.class.name.to_s })
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
            # TODO: Remove in v1.0
            if default.parameters.any? { |n, v| [:keyreq, :keyopt].include?(n) && [:model, :attribute, :locale, :options].include?(v) }
              warn %{
WARNING: Passing keyword arguments to a Proc in the Default plugin is
deprecated. See the API documentation for details.}
              return default.call(model: model, attribute: attribute, locale: locale, options: options)
            end
            args = [attribute, locale, options]
            args = args.first(default.arity) unless default.arity < 0
            model.instance_exec(*args, &default)
          else
            value
          end
        end
      end
    end
  end
end
