# frozen_string_literal: true
require "mobility/util"

module Mobility
  module Plugins
=begin

Falls back to one or more alternative locales in case no value is defined for a
given locale.

For +fallbacks: true+, Mobility will use the value of
{Mobility::Configuration#new_fallbacks} for the fallbacks instance. This
defaults to an instance of +I18n::Locale::Fallbacks+, but can be
configured (see {Mobility::Configuration}).

If a hash is passed to the +fallbacks+ option, a new fallbacks instance will be
created for the model with the hash defining additional fallbacks. To set a
default value for this hash, use set the value of `default_options[:fallbacks]`
in your Mobility configuration (see below).

In addition, fallbacks are disabled in certain situations. To explicitly disable
fallbacks when reading and writing, you can pass the <tt>fallback: false</tt>
option to the reader method. This can be useful to determine the actual
value of the translated attribute, including a possible +nil+ value.

The other situation where fallbacks are disabled is when the locale is
specified explicitly, either by passing a `locale` option to the accessor or by
using locale or fallthrough accessors. (See example below.)

You can also pass a locale or array of locales to the +fallback+ option to use
that locale or locales that read, e.g. <tt>fallback: :fr</tt> would fetch the
French translation if the value in the current locale was +nil+, whereas
<tt>fallback: [:fr, :es]</tt> would try French, then Spanish if the value in
the current locale was +nil+.

@see https://github.com/svenfuchs/i18n/wiki/Fallbacks I18n Fallbacks

@example With default fallbacks enabled (falls through to default locale)
  class Post
    extend Mobility
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
    extend Mobility
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
    extend Mobility
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

@example Fallbacks disabled
  class Post
    extend Mobility
    translates :title, fallbacks: { :'fr' => 'en' }, locale_accessors: true
  end

  I18n.default_locale = :en
  Mobility.locale = :en
  post = Post.new(title: "Mobility")

  Mobility.locale = :fr
  post.title
  #=> "Mobility"
  post.title(fallback: false)
  #=> nil
  post.title(locale: :fr)
  #=> nil
  post.title_fr
  #=> nil

@example Setting default fallbacks across all models
  Mobility.configure do |config|
    # ...
    config.default_options[:fallbacks] = { :'fr' => 'en' }
    # ...
  end

  class Post
    # Post will fallback from French to English by default
    translates :title, fallbacks: true
  end

=end
    module Fallbacks
      extend Plugin

      # Applies fallbacks plugin to attributes. Completely disables fallbacks
      # on model if option is +false+.
      included_hook do |_, backend_class|
        option = options[:fallbacks]
        backend_class.include(Methods.new(option)) unless option == false
      end

      class Methods < Module
        def initialize(fallbacks_option)
          define_read(convert_option_to_fallbacks(fallbacks_option))
        end

        private

        def define_read(fallbacks)
          define_method :read do |locale, fallback: true, **options|
            return super(locale, **options) if !fallback || options[:locale]

            locales = fallback == true ? fallbacks[locale] : [locale, *fallback]
            locales.each do |fallback_locale|
              value = super(fallback_locale, **options)
              return value if Util.present?(value)
            end

            super(locale, **options)
          end
        end

        def convert_option_to_fallbacks(option)
          if option.is_a?(::Hash)
            Mobility.new_fallbacks(option)
          elsif option == true
            Mobility.new_fallbacks
          else
            ::Hash.new { [] }
          end
        end
      end
    end
  end
end
