module Mobility
  module Backend
    class ActiveRecord::Columns
      include Base
      include Mobility::Backend::Columns

      def self.configure!(options)
        options[:locale_accessors] = false
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
