module Mobility
  module Backend
    module Table
      include OrmDelegator

      class TranslationsCache < Hash
        def initialize(model)
          super() { |hash, locale| hash[locale] = model.mobility_translation_for(locale) }
        end

        def for(attribute)
          cache = self

          Class.new do
            define_singleton_method :[] do |locale|
              cache[locale].send(attribute)
            end

            define_singleton_method :[]= do |locale, value|
              cache[locale].send("#{attribute}=", value)
            end
          end
        end
      end
    end
  end
end
