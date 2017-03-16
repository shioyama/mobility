module Mobility
  module Backend
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
    module Fallbacks
      # @!group Backend Accessors
      # @!macro backend_reader
      # @option options [Boolean] fallbacks +false+ to disable fallbacks on lookup
      def read(locale, fallback: nil, **_)
        if !options[:fallbacks].nil?
          warn "You passed an option with key 'fallbacks', which will be
            ignored. Did you mean 'fallback'?"
        end
        return super if fallback == false
        (fallback ? [locale, *fallback] : fallbacks[locale]).detect do |locale|
          value = super(locale)
          break value if value.present?
        end
      end

      private

      def fallbacks
        @fallbacks ||= Mobility.default_fallbacks
      end
    end
  end
end
