require "rails/generators/active_record"
require "active_record/migration"

module Mobility
  module ActiveRecordMigrationCompatibility
    def activerecord_migration_class
      if ::ActiveRecord::Migration.respond_to?(:current_version)
        "ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]"
      else
        "ActiveRecord::Migration"
      end
    end
  end
end
