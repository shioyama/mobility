# frozen_string_literal: true

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
    module Default
      # Applies default plugin to attributes.
      # @param [Attributes] attributes
      # @param [Object] option
      def self.apply(attributes, option)
        attributes.backend_class.include(self) unless option == Plugins::OPTION_UNSET
      end

      # @!group Backend Accessors
      # @!macro backend_reader
      # @option options [Boolean] default
      #   *false* to disable presence filter.
      def read(locale, accessor_options = {})
        default = accessor_options.has_key?(:default) ? accessor_options.delete(:default) : options[:default]
        if (value = super(locale, accessor_options)).nil?
          return default unless default.is_a?(Proc)
          args = [attribute, locale, accessor_options]
          args = args.first(default.arity) unless default.arity < 0
          model.instance_exec(*args, &default)
        else
          value
        end
      end
      # @!endgroup
    end
  end
end
