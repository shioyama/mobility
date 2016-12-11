module Mobility
  module Test
    class Database
      class << self
        def connect(orm)
          case orm
          when 'active_record'
            ::ActiveRecord::Base.establish_connection config[driver]
            ::ActiveRecord::Migration.verbose = false if in_memory?

            # don't really need this, but let's return something relevant
            ::ActiveRecord::Base.connection
          when 'sequel'
            adapter = config[driver]['adapter'].gsub(/^sqlite3$/,'sqlite')
            user = config[driver]['username']
            database = config[driver]['database']
            ::Sequel.connect(adapter: adapter, database: database, username: user)
          end
        end

        def auto_migrate
          Schema.migrate :up if in_memory?
        end

        def config
          @config ||= YAML::load(File.open(File.expand_path("../databases.yml", __FILE__)))
        end

        def driver
          (ENV["DB"] or "sqlite3").downcase
        end

        def in_memory?
          config[driver]["database"] == ":memory:"
        end
      end
    end
  end
end
