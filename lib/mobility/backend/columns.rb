module Mobility
  module Backend
    module Columns
      include OrmDelegator

      def read(locale, **options)
        model.send(column(locale))
      end

      def write(locale, value, **options)
        model.send("#{column(locale)}=", value)
      end

      def column(locale)
        Columns.column_name_for(attribute, locale)
      end

      def self.column_name_for(attribute, locale)
        normalized_locale = locale.to_s.downcase.sub("-", "_")
        "#{attribute}_#{normalized_locale}".to_sym
      end
    end
  end
end
