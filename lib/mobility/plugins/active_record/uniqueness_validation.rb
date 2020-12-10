module Mobility
  module Plugins
    module ActiveRecord
      module UniquenessValidation
        extend Plugin

        requires :query, include: false

        included_hook do |klass|
          klass.class_eval do
            unless const_defined?(:UniquenessValidator, false)
              self.const_set(:UniquenessValidator, Class.new(UniquenessValidator))

              def self.validates_uniqueness_of(*attr_names)
                validates_with(UniquenessValidator, _merge_attributes(attr_names))
              end
            end
          end
        end

        class UniquenessValidator < ::ActiveRecord::Validations::UniquenessValidator
          # @param [ActiveRecord::Base] record Translated model
          # @param [String] attribute Name of attribute
          # @param [Object] value Attribute value
          def validate_each(record, attribute, value)
            klass = record.class

            if ([*options[:scope]] + [attribute]).any? { |name| klass.mobility_attribute?(name) }
              return unless value.present?
              relation = klass.unscoped.__mobility_query_scope__ do |m|
                node = m.__send__(attribute)
                options[:case_sensitive] == false ? node.lower.eq(value.downcase) : node.eq(value)
              end
              relation = relation.where.not(klass.primary_key => record.id) if record.persisted?
              relation = mobility_scope_relation(record, relation)
              relation = relation.merge(options[:conditions]) if options[:conditions]

              if relation.exists?
                error_options = options.except(:case_sensitive, :scope, :conditions)
                error_options[:value] = value

                record.errors.add(attribute, :taken, **error_options)
              end
            else
              super
            end
          end

          private

          def mobility_scope_relation(record, relation)
            [*options[:scope]].inject(relation) do |scoped_relation, scope_item|
              scoped_relation.__mobility_query_scope__ do |m|
                m.__send__(scope_item).eq(record.send(scope_item))
              end
            end
          end
        end
      end
    end

    register_plugin(:active_record_uniqueness_validation, ActiveRecord::UniquenessValidation)
  end
end
