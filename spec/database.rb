require 'erb'

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
            password = config[driver]['password']
            database = config[driver]['database']
            port = config[driver]['port']
            host = config[driver]['host']
            ::Sequel.connect(adapter: adapter, database: database, username: user, password: password, port: port, host: host)
          end
        end

        def auto_migrate
          Schema.migrate :up if in_memory?
        end

        def config
          @config ||=
            begin
              erb = ERB.new(File.read(File.expand_path("../databases.yml", __FILE__)))
              YAML::load(erb.result)
            end
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
