module Mobility
  module Test
    class Database
      class << self
        def connect
          ::ActiveRecord::Base.establish_connection config[driver]

          if in_memory?
            ::ActiveRecord::Migration.verbose = false
            Schema.migrate :up
          end
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
