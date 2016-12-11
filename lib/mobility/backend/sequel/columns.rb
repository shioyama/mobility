module Mobility
  module Backend
    class Sequel::Columns
      include Base
      include Mobility::Backend::Columns

      def self.configure!(options)
        options[:locale_accessors] = false
      end

      setup do |attributes, options|
        attributes.each do |attribute|
          class_eval <<-EOM, __FILE__, __LINE__ + 1
            def self.first_by_#{attribute}(value)
              normalized_locale = Mobility.locale.to_s.downcase.sub("-", "_")
              where(:"#{attribute}_\#{normalized_locale}" => value).first
            end
          EOM
        end
      end
    end
  end
end
