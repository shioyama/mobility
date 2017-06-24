
module Mobility
  module Backend
    module PostgresQueryMethods
      private

      def define_query_methods(column_type)
        attributes_extractor = @attributes_extractor

        %w[exclude or where].each do |method_name|
          invert = method_name == "exclude"

          define_method method_name do |*cond, &block|
            if i18n_keys = attributes_extractor.call(cond.first)
              locale = Mobility.locale.to_s
              cond = cond.first

              i18n_query = i18n_keys.inject(::Sequel.expr(!invert)) do |expr, attr|
                value = cond.delete(attr)
                op = ::Sequel.send(:"#{column_type}_op", attr)
                contains_value = op.contains({ locale => value.to_s })
                has_key = op.has_key?(locale)
                if invert
                  expr.|(has_key & ~contains_value)
                else
                  expr.&(value.nil? ? ~has_key : contains_value)
                end
              end
              if method_name == "or"
                cond.empty? ? super(i18n_query, &block) : super(::Sequel.&(cond, i18n_query), &block)
              else
                super(cond, &block).where(i18n_query)
              end
            else
              super(*cond, &block)
            end
          end
        end
      end
    end
  end
end
