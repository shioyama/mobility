# frozen_string_literal: true

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

      default true

      requires :backend, include: :before
      requires :fallthrough_accessors

      initialize_hook do
        if options[:dirty] && !options[:fallthrough_accessors]
          warn 'The Dirty plugin depends on Fallthrough Accessors being enabled,'\
            'but fallthrough_accessors option is falsey'
        end
      end
    end

    register_plugin(:dirty, Dirty)
  end
end
