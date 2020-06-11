# frozen_string_literal: true
require "mobility/plugins/fallthrough_accessors"

module Mobility
  module Plugins
=begin

Dirty tracking for Mobility attributes. See class-specific implementations for
details.

@see Mobility::Plugins::ActiveModel::Dirty
@see Mobility::Plugins::ActiveRecord::Dirty
@see Mobility::Plugins::Sequel::Dirty

@note Dirty tracking can have unexpected results when combined with fallbacks.
  A change in the fallback locale value will not mark an attribute falling
  through to that locale as changed, even though it may look like it has
  changed. See the specs for details on expected behavior.

=end
    module Dirty
      extend Plugin

      depends_on :fallthrough_accessors

      initialize_hook do |dirty: nil|
        @options[:fallthrough_accessors] = true if dirty == true
      end

      included_hook do |model_class, backend_class, dirty: nil|
        if dirty
          include_dirty_modules(backend_class, model_class, *names)
        end
      end

      private

      def include_dirty_modules(backend_class, model_class, *attribute_names)
        dirty_module =
          if Loaded::ActiveRecord && model_class.ancestors.include?(::ActiveModel::Dirty)
            if (model_class < ::ActiveRecord::Base)
              require "mobility/plugins/active_record/dirty"
              Plugins::ActiveRecord::Dirty
            else
              require "mobility/plugins/active_model/dirty"
              Plugins::ActiveModel::Dirty
            end
          elsif Loaded::Sequel && model_class < ::Sequel::Model
            require "mobility/plugins/sequel/dirty"
            Plugins::Sequel::Dirty
          else
            raise ArgumentError, "#{model_class} does not support Dirty module."
          end
        backend_class.include dirty_module.const_get(:BackendMethods)
        model_class.include dirty_module.const_get(:MethodsBuilder).new(*attribute_names)
      end
    end

    register_plugin(:dirty, Dirty)
  end
end
