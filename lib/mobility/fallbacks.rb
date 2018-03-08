module Mobility
=begin

Subclasses +I18n::Locale::Fallbacks+ such that instances of this class
fall through to fallbacks defined in +I18n.fallbacks+. This allows models to
customize fallbacks while still falling through to any fallbacks defined
globally.

=end
  class Fallbacks < ::I18n::Locale::Fallbacks
    # @param [Symbol] locale
    # @return [Array] locales
    def [](locale)
      super | I18n.fallbacks[locale]
    end

    # For this set of fallbacks, return a new fallbacks hash.
    # @param [Hash] fallbacks
    # @return [I18n::Locale::Fallbacks,Mobility::Fallbacks] fallbacks hash
    def self.build(fallbacks)
      if I18n.respond_to?(:fallbacks)
        new(fallbacks)
      else
        I18n::Locale::Fallbacks.new(fallbacks)
      end
    end
  end
end
