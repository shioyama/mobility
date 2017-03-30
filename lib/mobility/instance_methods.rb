module Mobility
=begin

Instance methods attached to all model classes when model includes or extends
{Mobility}.

=end
  module InstanceMethods
    # Fetch backend for an attribute
    # @param [String] attribute Attribute
    def mobility_backend_for(attribute)
      send(Backend.method_name(attribute))
    end

    private

    def mobility_get(attribute, locale: Mobility.locale, **options)
      Mobility.enforce_available_locales!(locale)
      mobility_backend_for(attribute).read(locale.to_sym, options)
    end

    def mobility_present?(*args)
      mobility_get(*args).present?
    end

    def mobility_set(attribute, value, locale: Mobility.locale, **options)
      Mobility.enforce_available_locales!(locale)
      mobility_backend_for(attribute).write(locale.to_sym, value, **options)
    end
  end
end
