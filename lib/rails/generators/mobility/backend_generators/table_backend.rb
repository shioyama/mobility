# frozen-string-literal: true
require "rails/generators"

module Mobility
  module BackendGenerators
    class TableBackend < Mobility::BackendGenerators::Base
      source_root File.expand_path("../../templates", __FILE__)

      def create_migration_file
        if data_source_exists? && !self.class.migration_exists?(migration_dir, migration_file)
          migration_template "#{backend}_migration.rb", "db/migrate/#{migration_file}.rb"
        else
          super
        end
      end

      private

      alias_method :model_table_name, :table_name
      def table_name
        model_table_name = super
        "#{model_table_name.singularize}_translations"
      end

      def foreign_key
        "#{model_table_name.singularize}_id"
      end
    end
  end
end
