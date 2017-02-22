require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yaml"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :load_path do
  %w(lib spec).each do |path|
    $LOAD_PATH.unshift(File.expand_path("../#{path}", __FILE__))
  end
end

namespace :db do
  desc "Create the database"
  task :create => :load_path do
    require "database"
    driver = Mobility::Test::Database.driver
    config = Mobility::Test::Database.config[driver]
    exit if config["database"] == ":memory:"
    commands = {
      "mysql"    => "mysql -u #{config['username']} -e 'create database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'create database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
  end

  desc "Drop the database"
  task :drop => :load_path do
    require "database"
    driver = Mobility::Test::Database.driver
    config = Mobility::Test::Database.config[driver]
    exit if config["database"] == ":memory:"
    commands = {
      "mysql"    => "mysql -u #{config['username']} -e 'drop database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'drop database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
  end

  desc "Set up the database schema"
  task :up => :load_path do
    require "database"
    driver = Mobility::Test::Database.driver
    config = Mobility::Test::Database.config[driver]
    exit if config["database"] == ":memory:"
    require "spec_helper"
    Mobility::Test::Schema.up
  end

  desc "Drop and recreate the database schema"
  task :reset => [:drop, :create]
end
