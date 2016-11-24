module Mobility
  module Backend
    class Columns
      include Base

      def read(locale)
        model.send(column(locale))
      end

      def write(locale, value)
        model.send("#{column(locale)}=", value)
      end

      def column(locale)
        normalized_locale = locale.to_s.downcase.sub("-", "_")
        "#{attribute}_#{normalized_locale}".to_sym
      end
    end
  end
end
