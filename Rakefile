require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yaml"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :setup do
  %w(lib spec).each do |path|
    $LOAD_PATH.unshift(File.expand_path("../#{path}", __FILE__))
  end
  require "database"
  exit if config["database"] == ":memory:"
end

namespace :db do
  desc "Create the database"
  task create: :setup do
    commands = {
      "mysql"    => "mysql -u #{config['username']} -e 'create database #{config["database"]} default character set #{config["encoding"]} default collate #{config["collation"]};' >/dev/null",
      "postgres" => "psql -c 'create database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
    $?.success? ? puts("Database successfully created.") : puts("There was an error creating the database.")
  end

  desc "Drop the database"
  task drop: :setup do
    commands = {
      "mysql"    => "mysql -u #{config['username']} -e 'drop database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'drop database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
    $?.success? ? puts("Database successfully dropped.") : puts("There was an error dropping the database.")
  end

  desc "Set up the database schema"
  task up: :setup do
    require "spec_helper"
    Mobility::Test::Schema.up
  end

  desc "Drop and recreate the database schema"
  task :reset => [:drop, :create]

  def config
    Mobility::Test::Database.config[driver]
  end

  def driver
    Mobility::Test::Database.driver
  end
end
