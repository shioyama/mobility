# frozen_string_literal: true
require "mobility/util"

module Mobility
  module Plugins
=begin

Falls back to one or more alternative locales in case no value is defined for a
given locale.

For +fallbacks: true+, Mobility will use an instance of
+I18n::Locale::Fallbacks+, but this can be configured by overriding
+generate_fallbacks+ in the translations class.

If a hash is passed to the +fallbacks+ option, a new fallbacks instance will be
created for the model with the hash defining additional fallbacks. To set a
default value for this hash, pass this value to the plugin in your Mobility
configuration.

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
=end
    module Fallbacks
      extend Plugin

      default true
      requires :backend, include: :before

      # Applies fallbacks plugin to attributes. Completely disables fallbacks
      # on model if option is +false+.
      included_hook do |_, backend_class|
        unless options[:fallbacks] == false
          backend_class.include(BackendInstanceMethods)

          fallbacks =
            if options[:fallbacks].is_a?(Hash)
              generate_fallbacks(options[:fallbacks])
            elsif options[:fallbacks] == true
              generate_fallbacks({})
            else
              ::Hash.new { [] }
            end

          backend_class.singleton_class.attr_reader :fallbacks
          backend_class.instance_variable_set(:@fallbacks, fallbacks)
        end
      end

      private

      def generate_fallbacks(fallbacks)
        fallbacks_class = I18n.respond_to?(:fallbacks) ? I18nFallbacks : I18n::Locale::Fallbacks
        fallbacks_class.new(fallbacks)
      end

      class I18nFallbacks < ::I18n::Locale::Fallbacks
        def [](locale)
          super | I18n.fallbacks[locale]
        end
      end

      module BackendInstanceMethods
        def read(locale, fallback: true, **kwargs)
          return super(locale, **kwargs) if !fallback || kwargs[:locale]

          locales = fallback == true ? self.class.fallbacks[locale] : [locale, *fallback]
          locales.each do |fallback_locale|
            value = super(fallback_locale, **kwargs)
            return value if Util.present?(value)
          end

          super(locale, **kwargs)
        end
      end
    end

    register_plugin(:fallbacks, Fallbacks)
  end
end
