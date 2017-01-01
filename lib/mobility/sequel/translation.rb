module Mobility
  module Sequel
    module Translation
      def self.included(base)
        base.class_eval do
          plugin :validation_helpers

          # Paraphased from sequel_polymorphic gem
          #
          model = underscore(self.to_s)
          plural_model = pluralize(model)
          many_to_one :translatable,
            reciprocal: plural_model.to_sym,
            reciprocal_type: :many_to_one,
            setter: (proc do |able_instance|
              self[:translatable_id]   = (able_instance.pk if able_instance)
              self[:translatable_type] = (able_instance.class.name if able_instance)
            end),
            dataset: (proc do
              translatable_type = send :translatable_type
              translatable_id   = send :translatable_id
              return if translatable_type.nil? || translatable_id.nil?
              klass = self.class.send(:constantize, translatable_type)
              klass.where(klass.primary_key => translatable_id)
            end),
            eager_loader: (proc do |eo|
              id_map = {}
              eo[:rows].each do |model|
                model_able_type = model.send :translatable_type
                model_able_id = model.send :translatable_id
                model.associations[:translatable] = nil
                ((id_map[model_able_type] ||= {})[model_able_id] ||= []) << model if !model_able_type.nil? && !model_able_id.nil?
              end
              id_map.each do |klass_name, id_map|
                klass = constantize(camelize(klass_name))
                klass.where(klass.primary_key=>id_map.keys).all do |related_obj|
                  id_map[related_obj.pk].each do |model|
                    model.associations[:translatable] = related_obj
                  end
                end
              end
            end)

          def validate
            super
            validates_presence [:locale, :key, :translatable_id, :translatable_type]
            validates_unique   [:locale, :key, :translatable_id, :translatable_type]
          end

          def __mobility_get
            value
          end

          def __mobility_set(value)
            self.value = value
          end
        end
      end
    end
  end
end
