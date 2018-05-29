module Mobility
  module ActiveRecord
=begin

A backend-agnostic uniqueness validator for ActiveRecord translated attributes.
To use the validator, you must +extend Mobility+ before calling +validates+
(see example below).

@note This validator does not support case sensitivity, since doing so would
  significantly complicate implementation.

@example Validating uniqueness on translated model
  class Post < ActiveRecord::Base
    extend Mobility
    translates :title

    # This must come *after* extending Mobility.
    validates :title, uniqueness: true
  end
=end
    class UniquenessValidator < ::ActiveRecord::Validations::UniquenessValidator
      # @param [ActiveRecord::Base] record Translated model
      # @param [String] attribute Name of attribute
      # @param [Object] value Attribute value
      def validate_each(record, attribute, value)
        klass = record.class

        if (([*options[:scope]] + [attribute]).map(&:to_s) & klass.mobility_attributes).present?
          return unless value.present?
          relation = klass.send(Mobility.query_method) do |m|
            node = m.__send__(attribute)
            options[:case_sensitive] == false ? node.lower.eq(value.downcase) : node.eq(value)
          end
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
        [*options[:scope]].inject(relation) do |scoped_relation, scope_item|
          scoped_relation.send(Mobility.query_method) do |m|
            m.__send__(scope_item).eq(record.send(scope_item))
          end
        end
      end
    end
  end
end
