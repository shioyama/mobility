$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if !ENV['ORM'].nil? && (ENV['ORM'] != '')
  orm = ENV['ORM']
  raise ArgumentError, 'Invalid ORM' unless %w[active_record sequel].include?(orm)
  require orm
else
  orm = 'none'
end

require 'rails' if ENV['FEATURE'] == 'rails'

db = ENV['DB'] || 'none'
require 'pry-byebug'
require 'i18n'
require 'i18n/backend/fallbacks' if ENV['FEATURE'] == 'i18n_fallbacks'
require 'rspec'
require 'allocation_stats' if ENV['FEATURE'] == 'performance'
require 'json'

require 'mobility'

I18n.enforce_available_locales = true
I18n.available_locales = [:en, :'en-US', :ja, :fr, :de, :'de-DE', :cz, :pl, :pt, :'pt-BR']
I18n.default_locale = :en

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

  config.include Helpers::Plugins, type: :plugin
  config.include Helpers::PluginSetup, type: :plugin

  config.extend Helpers::Backend, type: :backend
  config.include Helpers::Plugins, type: :backend
  config.include Helpers::Translates, type: :backend

  config.extend Helpers::ActiveRecord, orm: :active_record
  config.extend Helpers::Sequel, orm: :sequel

  config.before :each do |example|
    if (version = example.metadata[:active_record_geq]) &&
        defined?(ActiveRecord) &&
        ActiveRecord::VERSION::STRING < version
      skip "Unsupported for Rails < #{version}"
    end
    # Always clear I18n.fallbacks to avoid "leakage" between specs
    reset_i18n_fallbacks
    Mobility.locale = :en

    # Remove once lowest supported version is Rails 6.2
    if defined?(ActiveSupport::Dependencies::Reference)
      ActiveSupport::Dependencies::Reference.clear!
    end

    # ensure this is reset in each run
    Mobility.reset_translations_class
  end

  unless orm == 'none'
    config.before :each do
      DatabaseCleaner.start
    end
    config.after :each do
      DatabaseCleaner.clean
    end
  end

  config.order = "random"
  config.filter_run_excluding orm: lambda { |v| v && ![*v].include?(orm&.to_sym) }, db: lambda { |v| v && ![*v].include?(db.to_sym) }
end
