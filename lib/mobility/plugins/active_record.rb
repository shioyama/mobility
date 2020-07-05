# frozen-string-literal: true
require "mobility/util"

module Mobility
  module Plugins
    module ActiveRecord
      extend Plugin

      depends_on :delegator, include: :before
      depends_on :active_model, include: :before

      def delegate_included(plugin, klass, backend_class)
        if klass < ::ActiveRecord::Base
          require_relative "./active_record/#{plugin}"
          ::Mobility::Plugins::ActiveRecord.const_get(Util.camelize(plugin)).new(self).call(klass, backend_class)
        else
          super
        end
      end
    end

    register_plugin(:active_record, ActiveRecord)
  end
end
