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

      default true
      requires :backend, include: :before

      module BackendMethods
        # @!group Backend Accessors
        # @!macro backend_reader
        # @option options [Boolean] presence
        #   *false* to disable presence filter.
        def read(locale, **kwargs)
          return super unless options[:presence]
          kwargs.delete(:presence) == false ? super : Presence[super]
        end

        # @!macro backend_writer
        # @option options [Boolean] presence
        #   *false* to disable presence filter.
        def write(locale, value, **kwargs)
          return super unless options[:presence]
          if kwargs.delete(:presence) == false
            super
          else
            super(locale, Presence[value], **kwargs)
          end
        end
        # @!endgroup
      end

      def self.[](value)
        (value == "") ? nil : value
      end
    end

    register_plugin(:presence, Presence)
  end
end
