# frozen-string-literal: true

module Mobility
  module Plugins
=begin

Defines methods for a set of locales to access translated attributes in those
locales directly with a method call, using a suffix including the locale:

  article.title_pt_br

If no locales are passed as an option to the initializer,
+Mobility.available_locales+ (i.e. +I18n.available_locales+, or Rails-set
available locales for a Rails application) will be used by default.

=end
    module LocaleAccessors
      extend Plugin

      default true

      # Apply locale accessors plugin to attributes.
      # @param [Translations] translations
      # @param [Boolean] option
      initialize_hook do |*names|
        if locales = options[:locale_accessors]
          locales = Mobility.available_locales if locales == true
          names.each do |name|
            locales.each do |locale|
              define_locale_reader(name, locale)
              define_locale_writer(name, locale)
            end
          end
        end
      end

      private

      def define_locale_reader(name, locale)
        warning_message = "locale passed as option to locale accessor will be ignored"
        normalized_locale = Mobility.normalize_locale(locale)

        module_eval <<-EOM, __FILE__, __LINE__ + 1
        def #{name}_#{normalized_locale}(options = {})
          return super() if options.delete(:super)
          warn "#{warning_message}" if options[:locale]
          #{name}(**options, locale: #{locale.inspect})
        end
        EOM

        module_eval <<-EOM, __FILE__, __LINE__ + 1
        def #{name}_#{normalized_locale}?(options = {})
          return super() if options.delete(:super)
          warn "#{warning_message}" if options[:locale]
          #{name}?(**options, locale: #{locale.inspect})
        end
        EOM
      end

      def define_locale_writer(name, locale)
        warning_message = "locale passed as option to locale accessor will be ignored"
        normalized_locale = Mobility.normalize_locale(locale)

        module_eval <<-EOM, __FILE__, __LINE__ + 1
        def #{name}_#{normalized_locale}=(value, options = {})
          return super(value) if options.delete(:super)
          warn "#{warning_message}" if options[:locale]
          public_send(:#{name}=, value, **options, locale: #{locale.inspect})
        end
        EOM
      end
    end

    register_plugin(:locale_accessors, LocaleAccessors)
  end
end
