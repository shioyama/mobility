Mobility.configure do |config|
  # Sets the default backend to use in models. This can be overridden in models
  # by passing +backend: ...+ to +translates+.
  config.default_backend = :key_value

  # By default, Mobility uses the +translates+ class method in models to
  # describe translated attributes, but you can configure this method to be
  # whatever you like. This may be useful if using Mobility alongside another
  # translation gem which uses the same method name.
  config.accessor_method = :translates

  # To query on translated attributes, you need to append a scope to your
  # model. The name of this scope is +i18n+ by default, but this can be changed
  # to something else.
  config.query_method    = :i18n

  # Uncomment and remove (or add) items to (from) this list to completely
  # disable/enable plugins globally (so they cannot be used and are never even
  # loaded). Note that if you remove an item from the list, you will not be
  # able to use the plugin at all, and any options for the plugin will be
  # ignored by models. (In most cases, you probably don't want to change this.)
  #
  # config.plugins = %i[
  #   query
  #   cache
  #   dirty
  #   fallbacks
  #   presence
  #   default
  #   attribute_methods
  #   fallthrough_accessors
  #   locale_accessors
  # ]

  # The translation cache is on by default, but you can turn it off by
  # uncommenting this line. (This may be helpful in debugging.)
  #
  # config.default_options[:cache] = false

  # Dirty tracking is disabled by default. Uncomment this line to enable it.
  # If you enable this, you should also enable +locale_accessors+ by default
  # (see below).
  #
  # config.default_options[:dirty] = true

  # No fallbacks are used by default. To define default fallbacks, uncomment
  # and set the default fallback option value here. A "true" value will use
  # whatever is defined by +I18n.fallbacks+ (if defined), or alternatively will
  # fallback to your +I18n.default_locale+.
  #
  # config.default_options[:fallbacks] = true

  # The Presence plugin converts empty strings to nil when fetching and setting
  # translations. By default it is on, uncomment this line to turn it off.
  #
  # config.default_options[:presence] = false

  # Set a default value to use if the translation is nil. By default this is
  # off, uncomment and set a default to use it across all models (you probably
  # don't want to do that).
  #
  # config.default_options[:default] = ...

  # Uncomment to enable locale_accessors by default on models. A true value
  # will use the locales defined either in
  # Rails.application.config.i18n.available_locales or I18n.available_locales.
  # If you want something else, pass an array of locales instead.
  #
  # config.default_options[:locale_accessors] = true

  # Uncomment to enable fallthrough accessors by default on models. This will
  # allow you to call any method with a suffix like _en or _pt_br, and Mobility
  # will catch the suffix and convert it into a locale in +method_missing+. If
  # you don't need this kind of open-ended fallthrough behavior, it's better
  # to use locale_accessors instead (which define methods) since method_missing
  # is very slow. (You can use both fallthrough and locale accessor plugins
  # together without conflict.)
  #
  # Note: The dirty plugin enables fallthrough_accessors by default.
  #
  # config.default_options[:fallthrough_accessors] = true

  # You can also include backend-specific default options. For example, if you
  # want to default to using the text-type translation table with the KeyValue
  # backend, you can set that as a default by uncommenting this line, or change
  # it to :string to default to the string-type translation table instead. (For
  # other backends, this option is ignored.)
  #
  # config.default_options[:type] = :text
end
