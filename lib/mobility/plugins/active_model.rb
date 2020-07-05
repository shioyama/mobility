module Mobility
  module Plugins
    module ActiveModel
      extend Plugin

      depends_on :delegator, include: :before

      def delegate_included(plugin, klass, backend_class)
        if plugin == :dirty && klass.ancestors.include?(::ActiveModel::Dirty)
          require_relative "./active_model/dirty"
          ::Mobility::Plugins::ActiveModel::Dirty.new(self).call(klass, backend_class)
        else
          super
        end
      end
    end

    register_plugin(:active_model, ActiveModel)
  end
end
