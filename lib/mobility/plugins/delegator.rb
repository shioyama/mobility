# frozen_string_literal: true

module Mobility
  module Plugins
=begin

Adds +delegate_included+ method to be overridden by delegating plugins
(active_record, sequel). This can then be called within other plugins to
delegate to a particular model-specific implementaiton of a plugin.

=end
    module Delegator
      extend Plugin

      def delegate_included(_name, _klass, _backend_class)
      end
    end

    register_plugin(:delegator, Delegator)
  end
end
