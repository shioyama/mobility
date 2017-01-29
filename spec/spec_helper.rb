$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if orm = ENV['ORM']
  require orm
else
  orm = 'none'
end
db = ENV['DB'] || 'none'
require 'pry-byebug'
require 'i18n'
require 'rspec'
require 'rspec/its'
require 'json'

require 'mobility'

I18n.enforce_available_locales = true
I18n.available_locales = [:en, :ja, :fr, :de, :cz, :pl]

Dir[File.expand_path("./spec/support/**/*.rb")].each { |f| require f }

unless orm == 'none'
  require "database"
  require "#{orm}/schema"

  require 'database_cleaner'
  DatabaseCleaner.strategy = :transaction

  DB = Mobility::Test::Database.connect(orm)
  DB.extension :pg_json, :pg_hstore if orm == 'sequel' && db == 'postgres'
  # for in-memory sqlite database
  Mobility::Test::Database.auto_migrate

  require "#{orm}/models"
end


RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before :each do
    Mobility.locale = :en
  end

  unless orm == 'none'
    config.before :each do
      DatabaseCleaner.start
    end
    config.after :each do
      DatabaseCleaner.clean
    end
  end

  config.filter_run_excluding orm: lambda { |v| v != orm.to_sym }, db: lambda { |v| v!= db.to_sym }
end
