module Mobility
  module AttributeMethods
    delegate :translated_attribute_names, to: :class

    def attributes
      super.merge(translated_attributes)
    end

    def translated_attributes
      translated_attribute_names.inject({}) do |attributes, name|
        attributes.merge(name.to_s => send(name))
      end
    end

    def original_changed_attributes
      @changed_attributes
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      delegate :translated_attribute_names, to: :mobility
    end
  end
end
