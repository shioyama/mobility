require "mobility/util"

module Mobility
  module Plugins
=begin

Falls back to one or more alternative locales in case no value is defined for a
given locale.

For +fallbacks: true+, Mobility will use the value of
{Mobility::Configuration#default_fallbacks} for the fallbacks instance. This
defaults to an instance of +I18n::Locale::Fallbacks+, but can be configured
(see {Mobility::Configuration}).

If a hash is passed to the +fallbacks+ option, a new fallbacks instance will be
created for the model with the hash defining additional fallbacks. 

In addition, fallbacks can be disabled when reading by passing <tt>fallback:
false</tt> to the reader method. This can be useful to determine the actual
value of the translated attribute, including a possible +nil+ value. You can
also pass a locale or array of locales to the +fallback+ option to use that
locale or locales that read, e.g. <tt>fallback: :fr</tt> would fetch the French
translation if the value in the current locale was +nil+, whereas <tt>fallback:
[:fr, :es]</tt> would try French, then Spanish if the value in the current
locale was +nil+.

@see https://github.com/svenfuchs/i18n/wiki/Fallbacks I18n Fallbacks

@example With default fallbacks enabled (falls through to default locale)
  class Post
    translates :title, fallbacks: true
  end

  I18n.default_locale = :en
  Mobility.locale = :en
  post = Post.new(title: "foo")

  Mobility.locale = :ja
  post.title
  #=> "foo"
 
  post.title = "bar"
  post.title
  #=> "bar"

@example With additional fallbacks enabled
  class Post
    translates :title, fallbacks: { :'en-US' => 'de-DE', :pt => 'de-DE' }
  end

  Mobility.locale = :'de-DE'
  post = Post.new(title: "foo")

  Mobility.locale = :'en-US'
  post.title
  #=> "foo"

  post.title = "bar"
  post.title
  #=> "bar"

@example Passing fallback option when reading value
  class Post
    translates :title, fallbacks: true
  end

  I18n.default_locale = :en
  Mobility.locale = :en
  post = Post.new(title: "Mobility")
  Mobility.with_locale(:fr) { post.title = "Mobilité" }

  Mobility.locale = :ja
  post.title
  #=> "Mobility"
  post.title(fallback: false)
  #=> nil
  post.title(fallback: :fr)
  #=> "Mobilité"
=end
    class Fallbacks < Module
      # Applies fallbacks plugin to attributes.
      # @param [Attributes] attributes
      # @param [Boolean] option
      def self.apply(attributes, option)
        attributes.backend_class.include(new(option)) unless option == false
      end

      def initialize(fallbacks_option)
        define_read(convert_option_to_fallbacks(fallbacks_option))
      end

      private

      def define_read(fallbacks)
        define_method :read do |locale, **options|
          fallback = options.delete(:fallback)

          if fallback == false || (fallback.nil? && fallbacks.nil?)
            super(locale, options)
          else
            (fallback.is_a?(Symbol) ? [locale, *fallback] : fallbacks[locale]).detect do |fallback_locale|
              value = super(fallback_locale, options)
              break value if Util.present?(value)
            end
          end
        end
      end

      def convert_option_to_fallbacks(option)
        if option.is_a?(Hash)
          Mobility.default_fallbacks(option)
        elsif option == true
          Mobility.default_fallbacks
        else
          option
        end
      end
    end
  end
end
