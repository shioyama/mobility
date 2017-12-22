module Mobility
  module ActiveRecord
=begin

A backend-agnostic uniqueness validator for ActiveRecord translated attributes.

@note This validator does not support case sensitivity, since doing so would
  significantly complicate implementation.

=end
    class UniquenessValidator < ::ActiveRecord::Validations::UniquenessValidator
      # @param [ActiveRecord::Base] record Translated model
      # @param [String] attribute Name of attribute
      # @param [Object] value Attribute value
      def validate_each(record, attribute, value)
        klass = record.class

        if ((Array(options[:scope]) + [attribute]).map(&:to_s) & klass.translated_attribute_names).present?
          warn %{
WARNING: The Mobility uniqueness validator for translated attributes does not
support case-insensitive validation. This option will be ignored.
} if options[:case_sensitive] == false
          return unless value.present?
          relation = klass.send(Mobility.query_method).where(attribute => value)
          relation = relation.where.not(klass.primary_key => record.id) if record.persisted?
          relation = mobility_scope_relation(record, relation)
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

      private

      def mobility_scope_relation(record, relation)
        Array(options[:scope]).inject(relation) do |scoped_relation, scope_item|
          scoped_relation.where(scope_item => record.send(scope_item))
        end
      end
    end
  end
end
