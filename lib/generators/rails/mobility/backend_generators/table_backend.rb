# frozen-string-literal: true
require "rails/generators"

module Mobility
  module BackendGenerators
    class TableBackend < Mobility::BackendGenerators::Base
      source_root File.expand_path("../../templates", __FILE__)

      def create_migration_file
        if table_exists? && !self.class.migration_exists?(migration_dir, migration_file)
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

      def translation_index_name
        truncate_index_name("index_#{table_name}_on_#{foreign_key}")
      end

      def translation_locale_index_name
        truncate_index_name("index_#{table_name}_on_locale")
      end

      def translation_unique_index_name
        truncate_index_name("index_#{table_name}_on_#{foreign_key}_and_locale")
      end
    end
  end
end
