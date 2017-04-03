# frozen-string-literal: true

module Mobility
=begin

Defines +method_missing+ and +respond_to_missing?+ methods for a set of
attributes such that a method call using a locale accessor, like:

  article.title_pt_br

will return the value of +article.title+ with the locale set to +pt-BR+ around
the method call. The class is called "FallthroughAccessors" because when
included in a model class, locale-specific methods will be available even if
not explicitly defined with the +locale_accessors+ option.

This is a less efficient (but more open-ended) implementation of locale
accessors, for use in cases where the locales to be used are not known when the
model class is generated.

@example Using fallthrough locales on a plain old ruby class
  class Post
    def title
      "title in #{Mobility.locale}"
    end
    include Mobility::FallthroughAccessors.new("title")
  end

  Mobility.locale = :en
  post = Post.new
  post.title
  #=> "title in en"
  post.title_fr
  #=> "title in fr"

=end
  class FallthroughAccessors < Module
    # @param [String] One or more attributes
    def initialize(*attributes)
      method_name_regex = /\A(#{attributes.join('|'.freeze)})_([a-z]{2}(_[a-z]{2})?)(=?|\??)\z/.freeze

      define_method :method_missing do |method_name, *arguments, &block| if method_name =~ method_name_regex
          attribute = $1.to_sym
          locale, suffix = $2.split('_'.freeze)
          locale = "#{locale}-#{suffix.upcase}".freeze if suffix
          Mobility.with_locale(locale) { public_send("#{attribute}#{$4}".freeze, *arguments) }
        else
          super(method_name, *arguments, &block)
        end
      end

      define_method :respond_to_missing? do |method_name, include_private = false|
        (method_name =~ method_name_regex) || super(method_name, include_private)
      end
    end
  end
end
