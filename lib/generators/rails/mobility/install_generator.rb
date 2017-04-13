require "rails/generators"
require "rails/generators/active_record"

module Mobility
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

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
      create_file(
        "config/initializers/mobility.rb",
        "Mobility.configure do |config|\n  config.default_backend = :key_value\n  config.accessor_method = :translates\n  config.query_method = :i18n\nend"
      )
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
