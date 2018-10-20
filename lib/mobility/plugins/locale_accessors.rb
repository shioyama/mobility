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

@example
  class Post
    def title
      "title in #{Mobility.locale}"
    end
    include Mobility::Plugins::LocaleAccessors.new("title", locales: [:en, :fr])
  end

  Mobility.locale = :en
  post = Post.new
  post.title
  #=> "title in en"
  post.title_fr
  #=> "title in fr"

=end
    module LocaleAccessors
      class << self
        # Apply locale accessors plugin to attributes.
        # @param [Attributes] attributes
        # @param [Boolean] option
        def apply(attributes, option)
          if locales = option
            locales = Mobility.config.default_accessor_locales if locales == true
            attributes.names.each do |name|
              locales.each do |locale|
                define_reader(attributes, name, locale)
                define_writer(attributes, name, locale)
              end
            end
          end
        end

        private

        def define_reader(mod, name, locale)
          warning_message = "locale passed as option to locale accessor will be ignored"
          normalized_locale = Mobility.normalize_locale(locale)

          mod.module_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{name}_#{normalized_locale}(options = {})
            return super() if options.delete(:super)
            warn "#{warning_message}" if options[:locale]
            #{name}(**options, locale: :'#{locale}')
          end

          def #{name}_#{normalized_locale}?(options = {})
            return super() if options.delete(:super)
            warn "#{warning_message}" if options[:locale]
            #{name}?(**options, locale: :'#{locale}')
          end
          EOM
        end

        def define_writer(mod, name, locale)
          warning_message = "locale passed as option to locale accessor will be ignored"
          normalized_locale = Mobility.normalize_locale(locale)

          mod.module_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{name}_#{normalized_locale}=(value, options = {})
            return super(value) if options.delete(:super)
            warn "#{warning_message}" if options[:locale]
            public_send(:#{name}=, value, **options, locale: :'#{locale}')
          end
          EOM
        end
      end
    end
  end
end
