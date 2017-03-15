# frozen-string-literal: true
require "rails/generators"

module Mobility
  module BackendGenerators
    class ColumnBackend < Mobility::BackendGenerators::Base
      source_root File.expand_path("../../templates", __FILE__)

      def initialize(*args)
        super
        unless table_exists?
          raise NoTableDefined, "The table #{table_name} does not exist. Create it first before generating translated columns."
        end
        unless I18n.available_locales.present?
          raise NoAvailableLocales, "You must set I18n.available_locales to use the column backend generator."
        end
      end
    end

    class NoTableDefined < StandardError; end
    class NoAvailableLocales < StandardError; end
  end
end
