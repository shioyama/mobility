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

      depends_on :backend, include: :before
      depends_on :fallthrough_accessors, include: :after

      initialize_hook do
        @options[:fallthrough_accessors] = true if options[:dirty]
      end
    end

    register_plugin(:dirty, Dirty)
  end
end
