# frozen-string-literal: true
require "rails/generators/active_record/migration/migration_generator"

module Mobility
  module BackendGenerators
    class Base < ::Rails::Generators::NamedBase
      argument :attributes, type: :array, default: []
      include ::ActiveRecord::Generators::Migration
      include ::Mobility::ActiveRecordMigrationCompatibility

      def create_migration_file
        if behavior == :invoke && self.class.migration_exists?(migration_dir, migration_file)
          ::Kernel.warn "Migration already exists: #{migration_file}"
        else
          migration_template "#{template}.rb", "db/migrate/#{migration_file}.rb"
        end
      end

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def backend
        self.class.name.split('::').last.gsub(/Backend$/,'').underscore
      end

      protected

      def attributes_with_index
        attributes.select { |a| !a.reference? && a.has_index? }
      end

      def translation_index_name(column, *columns)
        truncate_index_name("index_#{table_name}_on_#{[column, *columns].join('_and_')}")
      end

      private

      def check_data_source!
        unless data_source_exists?
          raise NoTableDefined, "The table #{table_name} does not exist. Create it first before generating translated columns."
        end
      end

      def data_source_exists?
        connection.data_source_exists?(table_name)
      end

      def connection
        ::ActiveRecord::Base.connection
      end

      def truncate_index_name(index_name)
        if index_name.size < connection.index_name_length
          index_name
        else
          "index_#{Digest::SHA1.hexdigest(index_name)}"[0, connection.index_name_length].freeze
        end
      end

      def template
        "#{backend}_translations"
      end

      def migration_dir
        File.expand_path("db/migrate")
      end

      def migration_file
        "create_#{file_name}_#{attributes.map(&:name).join('_and_')}_translations_for_mobility_#{backend}_backend"
      end
    end

    class NoTableDefined < StandardError; end
  end
end
