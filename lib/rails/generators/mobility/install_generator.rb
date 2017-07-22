require "rails/generators"
require "rails/generators/active_record"
require_relative "./active_record_migration_compatibility"

module Mobility
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration
    include ::Mobility::ActiveRecordMigrationCompatibility

    desc "Generates migrations to add translations tables."

    source_root File.expand_path("../templates", __FILE__)
    class_option(
      :without_tables,
      type: :boolean,
      default: false,
      desc: "Skip creating translations tables."
    )

    def create_migration_file
      add_mobility_migration("create_text_translations")   unless options.without_tables?
      add_mobility_migration("create_string_translations") unless options.without_tables?
    end

    def create_initializer
      copy_file "initializer.rb", "config/initializers/mobility.rb"
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected

    def add_mobility_migration(template)
      migration_dir = File.expand_path("db/migrate")
      if self.class.migration_exists?(migration_dir, template)
        ::Kernel.warn "Migration already exists: #{template}"
      else
        migration_template "#{template}.rb", "db/migrate/#{template}.rb"
      end
    end
  end
end
