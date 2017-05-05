module Mobility
  module ActiveRecord
    class UniquenessValidator < ::ActiveRecord::Validations::UniquenessValidator
      def validate_each(record, attribute, value)
        klass = record.class
        if klass.translated_attribute_names.include?(attribute.to_s) ||
            (Array(options[:scope]).map(&:to_s) & klass.translated_attribute_names).present?
          return unless value.present?
          relation = klass.send(Mobility.query_method).where(attribute => value)
          relation = relation.where.not(klass.primary_key => record.id) if record.persisted?
          Array(options[:scope]).each do |scope_item|
            relation = relation.where(scope_item => record.send(scope_item))
          end
          relation = relation.merge(options[:conditions]) if options[:conditions]

          if relation.exists?
            error_options = options.except(:case_sensitive, :scope, :conditions)
            error_options[:value] = value

            record.errors.add(attribute, :taken, error_options)
          end
        else
          super
        end
      end
    end
  end
end
