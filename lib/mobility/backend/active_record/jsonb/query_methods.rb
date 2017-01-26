module Mobility
  module Backend
    class ActiveRecord::Jsonb::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        super
        attributes_extractor = @attributes_extractor

        define_method :where! do |opts, *rest|
          if i18n_keys = attributes_extractor.call(opts)
            locale = Mobility.locale
            opts = opts.with_indifferent_access

            result = i18n_keys.inject(all) do |scope, attr|
              value = opts.delete(attr)
              if value.nil?
                scope.where.not("#{table_name}.#{attr} ? :locale", locale: locale)
              else
                scope.where!("#{table_name}.#{attr} @> (?)::jsonb", { locale => value }.to_json)
              end
            end
            result = result.where!(opts, *rest) if opts.present?
            result
          else
            super(opts, *rest)
          end
        end
      end

      def extended(relation)
        super
        attributes_extractor = @attributes_extractor
        table_name = relation.model.table_name

        mod = Module.new do
          define_method :not do |opts, *rest|
            if i18n_keys = attributes_extractor.call(opts)
              locale = Mobility.locale
              opts = opts.with_indifferent_access

              i18n_keys.inject(relation) { |scope, attr|
                scope.where!("#{table_name}.#{attr} ? :locale", locale: locale).
                  where.not("#{table_name}.#{attr} @> (?)::jsonb", { locale => opts.delete(attr) }.to_json)
              }.where.not(opts, *rest)
            else
              super(opts, *rest)
            end
          end
        end
        relation.model.const_get(:MobilityWhereChain).prepend(mod)
      end
    end
  end
end
