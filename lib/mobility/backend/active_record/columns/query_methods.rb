module Mobility
  module Backend
    class ActiveRecord::Columns::QueryMethods < Backend::ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        @attributes = attributes

        define_method :where! do |opts, *rest|
          if opts.is_a?(Hash) && (keys = opts.keys.map(&:to_s) & attributes).present?
            opts = opts.stringify_keys
            keys.each do |attribute|
              attr_with_locale = Mobility::Backend::Columns.column_name_for(attribute, Mobility.locale)
              opts[attr_with_locale] = opts.delete(attribute)
            end
          end
          super(opts, *rest)
        end

        attributes.each do |attribute|
          define_method :"find_by_#{attribute}" do |value|
            find_by(Mobility::Backend::Columns.column_name_for(attribute, Mobility.locale) => value)
          end
        end
      end

      def extended(relation)
        super
        attributes = @attributes
        model_class = relation.model
        mod = Module.new do
          define_method :not do |opts, *rest|
            if opts.is_a?(Hash) && (keys = opts.keys.map(&:to_s) & attributes).present?
              opts = opts.stringify_keys
              keys.each do |attr|
                attr_with_locale = Mobility::Backend::Columns.column_name_for(attr, Mobility.locale)
                opts[attr_with_locale] = opts.delete(attr)
              end
            end
            super(opts, *rest)
          end
        end
        model_class.const_get(:MobilityWhereChain).prepend(mod)
      end
    end
  end
end
