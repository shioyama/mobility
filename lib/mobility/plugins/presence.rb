# frozen_string_literal: true
require "mobility/util"

module Mobility
  module Plugins
=begin

Applies presence filter to values fetched from backend and to values set on
backend. Included by default, but can be disabled with +presence: false+ option.

@note For performance reasons, the presence plugin filters only for empty
  strings, not other values continued "blank" like empty arrays.

=end
    module Presence
      # Applies presence plugin to attributes.
      # @param [Attributes] attributes
      # @param [Boolean] option
      def self.apply(attributes, option)
        attributes.backend_class.include(self) if option
      end

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
          super(locale, Presence[value], options)
        end
      end
      # @!endgroup

      def self.[](value)
        (value == "") ? nil : value
      end
    end
  end
end
