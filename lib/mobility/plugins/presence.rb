# frozen_string_literal: true
require "mobility/util"

module Mobility
  module Plugins
=begin

Applies presence filter to values fetched from backend and to values set on
backend.

@note For performance reasons, the presence plugin filters only for empty
  strings, not other values continued "blank" like empty arrays.

=end
    module Presence
      extend Plugin

      # Applies presence plugin to attributes.
      included_hook do |_, backend_class|
        backend_class.include(BackendMethods) if options[:presence]
      end

      module BackendMethods
        # @!group Backend Accessors
        # @!macro backend_reader
        # @option options [Boolean] presence
        #   *false* to disable presence filter.
        def read(locale, **options)
          options.delete(:presence) == false ? super : Presence[super]
        end

        # @!macro backend_writer
        # @option options [Boolean] presence
        #   *false* to disable presence filter.
        def write(locale, value, **options)
          if options.delete(:presence) == false
            super
          else
            super(locale, Presence[value], **options)
          end
        end
        # @!endgroup
      end

      def self.[](value)
        (value == "") ? nil : value
      end
    end
  end
end
