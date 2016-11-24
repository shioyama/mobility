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

      setup do |attributes, options|
        attributes.each do |attribute|
          class_eval <<-EOM, __FILE__, __LINE__ + 1
            def self.find_by_#{attribute}(value)
              normalized_locale = Mobility.locale.to_s.downcase.sub("-", "_")
              send("find_by_#{attribute}_" + normalized_locale, value)
            end
          EOM
        end
      end
    end
  end
end
