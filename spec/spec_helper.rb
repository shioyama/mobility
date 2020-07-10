$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if !ENV['ORM'].nil? && (ENV['ORM'] != '')
  orm, orm_version = ENV['ORM'], ENV['ORM_VERSION']

  case orm
  when 'active_record'
    ENV['RAILS_VERSION'] = orm_version || '6.0'
  when 'sequel'
    ENV['SEQUEL_VERSION'] = orm_version || '5'
  else
    raise ArgumentError, 'Invalid ORM'
  end

  require orm
else
  orm = nil
end

db = ENV['DB'] || 'none'
require 'pry-byebug'
require 'i18n'
require 'i18n/backend/fallbacks' if ENV['FEATURE'] == 'i18n_fallbacks'
require 'rspec'
require 'allocation_stats' if ENV['FEATURE'] == 'performance'
require 'json'

require 'mobility'
require "mobility/backends/null"

# Enable default plugins
Mobility.configure do |config|
  config.plugins *(%i[
    backend
    reader
    writer
    query
    cache
    dirty
    fallbacks
    presence
    default
    fallthrough_accessors
    locale_accessors
  ] + [orm]).compact
  config.plugin :attribute_methods if orm == 'active_record'
end

I18n.enforce_available_locales = true
I18n.available_locales = [:en, :'en-US', :ja, :fr, :de, :'de-DE', :cz, :pl, :pt, :'pt-BR']
I18n.default_locale = :en

Dir[File.expand_path("./spec/support/**/*.rb")].each { |f| require f }

if orm
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
  config.include Helpers
  config.include Mobility::Util
  if defined?(ActiveSupport)
    require 'active_support/testing/time_helpers'
    config.include ActiveSupport::Testing::TimeHelpers
  end

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before :each do |example|
    if (version = example.metadata[:rails_version_geq]) && (ENV['RAILS_VERSION'] < version)
      skip "Unsupported for Rails < #{version}"
    end
    # Always clear I18n.fallbacks to avoid "leakage" between specs
    reset_i18n_fallbacks
    Mobility.locale = :en
  end

  if orm
    config.before :each do
      DatabaseCleaner.start
    end
    config.after :each do
      DatabaseCleaner.clean
    end
  end

  config.order = "random"
  config.filter_run_excluding orm: lambda { |v| ![*v].include?(orm&.to_sym) || (orm && (v == 'none')) }, db: lambda { |v| ![*v].include?(db.to_sym) }
end

class TestAttributes < Mobility::Attributes
end
