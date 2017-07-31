module Mobility
  module Backends
    class Sequel::Column::QueryMethods < Sequel::QueryMethods
      def initialize(attributes, _)
        super
        attributes_extractor = @attributes_extractor

        %w[exclude or where].each do |method_name|
          define_method method_name do |*conds, &block|
            if keys = attributes_extractor.call(conds.first)
              cond = conds.first.dup
              keys.each { |attr| cond[Column.column_name_for(attr)] = cond.delete(attr) }
              super(cond, &block)
            else
              super(*conds, &block)
            end
          end
        end

        attributes.each do |attribute|
          define_method :"first_by_#{attribute}" do |value|
            where(attribute.to_sym => value).first
          end
        end
      end
    end
  end
end
