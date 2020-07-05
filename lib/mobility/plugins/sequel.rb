# frozen-string-literal: true
require "mobility/util"

module Mobility
  module Plugins
    module Sequel
      extend Plugin

      depends_on :delegator, include: :before

      def delegate_included(plugin, klass, backend_class)
        if klass < ::Sequel::Model
          require_relative "./sequel/#{plugin}"
          ::Mobility::Plugins::ActiveModel.const_get(Util.camelize(plugin)).new(self).call(klass, backend_class)
        else
          super
        end
      end
    end

    register_plugin(:sequel, Sequel)
  end
end
