# frozen_string_literal: true
require 'i18n'
require 'request_store'
require 'mobility/version'

=begin

Mobility is a gem for storing and retrieving localized data through attributes
on a class.

There are two ways to translate attributes on a class, both of which are
variations on the same basic mechanism. The first and most common way is to
extend the `Mobility` module, which adds a class method +translates+.
Translated attributes can then be defined like this:

  class Post
    extend Mobility
    translates :title, backend: :key_value
  end

Behind the scenes, +translates+ simply creates an instance of
+Mobility.translations_class+, passes it whatever arguments are passed to
+translates+, and includes the instance (which is a module) into the class.

So the above example is equivalent to:

  class Post
    Mobility.translations_class.new(:title, backend: :key_value)
  end

`Mobility.translations_class` is a subclass of `Mobility::Translations` created
when `Mobility.configure` is called to configure Mobility. In fact, when you
call `Mobility.configure`, it is the subclass of `Mobility::Translations` which
is passed to the block as `config` (or as `self` if no argument is passed to
the block). Plugins and plugin configuration is all applied to the same
`Mobility.translations_class`.

There is another way to use Mobility, which is to create your own subclass or
subclasses of +Mobility::Translations+ and include them explicitly, without
using +translates+.

For example:

  class Translations < Mobility::Translations
    plugins do
      backend :key_value
      # ...
    end
  end

  class Post
    include Translations.new(:title)
  end

This usage might be handy if, for example, you want to have more complex
configuration, where some models use some plugins while others do not. Since
`Mobility::Translations` is a class like any other, you can subclass it and
define plugins specifically on the subclass which are not present on its
parent:

  class TranslationsWithFallbacks < Translations
    plugins do
      fallbacks
    end
  end

  class Comment
    include TranslationsWithFallbacks.new(:author)
  end

In this case, +Comment+ uses +TranslationsWithFallbacks+ and thus has the
fallbacks plugin, whereas +Post+ uses +Translations+ which does not have that
plugin enabled.

=end

def ruby2_keywords(*); end unless respond_to?(:ruby2_keywords, true)

module Mobility
  # A generic exception used by Mobility.
  class Error < StandardError
  end

  require "mobility/backend"
  require "mobility/backends"
  require "mobility/plugin"
  require "mobility/plugins"
  require "mobility/translations"

  CALL_COMPILABLE_REGEXP = /\A[a-zA-Z_]\w*[!?]?\z/
  private_constant :CALL_COMPILABLE_REGEXP

  require "rails/generators/mobility/generators" if defined?(Rails) && defined?(ActiveRecord)

  class << self
    def extended(model_class)
      def model_class.translates(*args, **options)
        include Mobility.translations_class.new(*args, **options)
      end
    end

    # Extends model with this class so that +include Mobility+ is equivalent to
    # +extend Mobility+ (but +extend+ is preferred).
    # @param model_class
    def included(model_class)
      model_class.extend self
    end

    # Alias to default backend defined on *translations_class+.
    # @return [Symbol,Class]
    def default_backend
      translations_class.defaults[:backend]&.first
    end

    # Configure Mobility
    # @yield [Mobility::Translations]
    def configure(&block)
      translates_with(Class.new(Translations)) unless @translations_class
      if block.arity == 0
        translations_class.instance_exec(&block)
      else
        yield translations_class
      end
    end

    def translates_with(pluggable)
      raise ArgumentError, "translations class must be a subclass of Module." unless Module === pluggable
      @translations_class = pluggable
    end

    def translations_class
      @translations_class ||
        raise(Error, "Mobility has not been configured. "\
              "Configure with Mobility.configure, or assign a translations class with Mobility.translates_with(<class>)")
    end

    def reset_translations_class
      @translations_class = nil
    end

    # @!group Locale Accessors
    # @return [Symbol] Mobility locale
    def locale
      read_locale || I18n.locale
    end

    # Sets Mobility locale
    # @param [Symbol] locale Locale to set
    # @raise [InvalidLocale] if locale is nil or not in
    #   +Mobility.available_locales+ (if +I18n.enforce_available_locales+ is +true+)
    # @return [Symbol] Locale
    def locale=(locale)
      set_locale(locale)
    end

    # Sets Mobility locale around block
    # @param [Symbol] locale Locale to set in block
    # @yield [Symbol] Locale
    def with_locale(locale)
      previous_locale = read_locale
      begin
        set_locale(locale)
        yield(locale)
      ensure
        set_locale(previous_locale)
      end
    end
    # @!endgroup

    # @return [RequestStore] Request store
    def storage
      RequestStore.store
    end

    # Return normalized locale
    # @param [String,Symbol] locale
    # @return [String] Normalized locale
    # @example
    #   Mobility.normalize_locale(:ja)
    #   #=> "ja"
    #   Mobility.normalize_locale("pt-BR")
    #   #=> "pt_br"
    def normalize_locale(locale = Mobility.locale)
      "#{locale.to_s.downcase.tr("-", "_")}"
    end
    alias_method :normalized_locale, :normalize_locale

    # Return normalized locale accessor name
    # @param [String,Symbol] attribute
    # @param [String,Symbol] locale
    # @return [String] Normalized locale accessor name
    # @raise [ArgumentError] if generated accessor has an invalid format
    # @example
    #   Mobility.normalize_locale_accessor(:foo, :ja)
    #   #=> "foo_ja"
    #   Mobility.normalize_locale_accessor(:bar, "pt-BR")
    #   #=> "bar_pt_br"
    def normalize_locale_accessor(attribute, locale = Mobility.locale)
      "#{attribute}_#{normalize_locale(locale)}".tap do |accessor|
        unless CALL_COMPILABLE_REGEXP.match(accessor)
          raise ArgumentError, "#{accessor.inspect} is not a valid accessor"
        end
      end
    end

    # Check that a non-nil locale is valid. (Does not actually parse locale to
    # check its format.)
    # @raise [InvalidLocale] if locale is not a Symbol or not available
    def validate_locale!(locale)
      raise Mobility::InvalidLocale.new(locale) unless Symbol === locale
      enforce_available_locales!(locale) if I18n.enforce_available_locales
    end

    # Raises InvalidLocale exception if the locale passed in is present but not available.
    # @param [String,Symbol] locale
    # @raise [InvalidLocale] if locale is present but not available
    def enforce_available_locales!(locale)
      raise Mobility::InvalidLocale.new(locale) unless (locale.nil? || available_locales.include?(locale.to_sym))
    end

    # Returns available locales. Defaults to I18n.available_locales, but will
    # use Rails.application.config.i18n.available_locales if Rails is loaded
    # and config is non-nil.
    # @return [Array<Symbol>] Available locales
    # @note The special case for Rails is necessary due to the fact that Rails
    #   may load the model before setting +I18n.available_locales+. If we
    #   simply default to +I18n.available_locales+, we may define many more
    #   methods (in LocaleAccessors) than is really necessary.
    def available_locales
      if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        Rails.application.config.i18n.available_locales&.map(&:to_sym) || I18n.available_locales
      else
        I18n.available_locales
      end
    end

    protected

    def read_locale
      storage[:mobility_locale]
    end

    def set_locale(locale)
      locale = locale.to_sym if String === locale
      validate_locale!(locale) if locale
      storage[:mobility_locale] = locale
    end
  end

  class InvalidLocale < I18n::InvalidLocale; end
  class NotImplementedError < StandardError; end
end
