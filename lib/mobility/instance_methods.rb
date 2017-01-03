module Mobility
  module InstanceMethods
    def mobility_backend_for(attribute)
      send(Backend.method_name(attribute))
    end

    private

    def mobility_get(attribute, **options)
      locale = options.delete(:locale) || Mobility.locale
      mobility_backend_for(attribute).read(locale.to_sym, options).presence
    end

    def mobility_set(attribute, value, locale: Mobility.locale)
      mobility_backend_for(attribute).write(locale.to_sym, value.presence)
    end
  end
end
