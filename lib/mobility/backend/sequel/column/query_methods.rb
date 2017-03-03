module Mobility
  module Backend
    class Sequel::Column::QueryMethods < Backend::Sequel::QueryMethods
      def initialize(attributes, **)
        super
        attributes_extractor = @attributes_extractor

        define_method :_filter_or_exclude do |invert, clause, cond, &block|
          if keys = attributes_extractor.call(cond)
            cond = cond.dup
            keys.each { |attr| cond[Column.column_name_for(attr)] = cond.delete(attr) }
          end
          super(invert, clause, cond, &block)
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
