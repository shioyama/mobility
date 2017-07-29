# frozen-string-literal: true

module Mobility
=begin

Defines methods for a set of locales to access translated attributes in those
locales directly with a method call, using a suffix including the locale:

  article.title_pt_br

If no locales are passed as an option to the initializer,
+I18n.available_locales+ will be used by default.

@example
  class Post
    def title
      "title in #{Mobility.locale}"
    end
    include Mobility::LocaleAccessors.new("title", locales: [:en, :fr])
  end

  Mobility.locale = :en
  post = Post.new
  post.title
  #=> "title in en"
  post.title_fr
  #=> "title in fr"

=end
  class LocaleAccessors < Module
    # Apply locale accessors option module to attributes.
    # @param [Attributes] attributes
    # @param [Boolean] option
    def self.apply(attributes, option)
      if accessor_locales = option
        accessor_locales = Mobility.config.default_accessor_locales if accessor_locales == true
        attributes.model_class.include new(*attributes.names, locales: accessor_locales)
      end
    end

    # @param [String] One or more attribute names
    # @param [Array<Symbol>] Locales
    def initialize(*attribute_names, locales: I18n.available_locales)
      warning_message = "locale passed as option to locale accessor will be ignored".freeze

      attribute_names.each do |name|
        locales.each do |locale|
          normalized_locale = Mobility.normalize_locale(locale)
          define_method "#{name}_#{normalized_locale}" do |**options|
            return super() if options.delete(:super)
            warn warning_message if options.delete(:locale)
            Mobility.with_locale(locale) { send(name, options) }
          end
          define_method "#{name}_#{normalized_locale}?" do |**options|
            return super() if options.delete(:super)
            warn warning_message if options.delete(:locale)
            Mobility.with_locale(locale) { send("#{name}?", options) }
          end
          define_method "#{name}_#{normalized_locale}=" do |value, **options|
            return super(value) if options.delete(:super)
            warn warning_message if options.delete(:locale)
            Mobility.with_locale(locale) { send("#{name}=", value, options) }
          end
        end
      end
    end
  end
end
