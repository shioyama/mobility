$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'active_record'
require 'pry-byebug'
require 'i18n'
require 'rspec'
require 'rspec/its'
require 'shoulda-matchers'

require 'mobility'

I18n.enforce_available_locales = true
I18n.available_locales = [:en, :ja, :fr, :de, :cz, :pl]

Dir[File.expand_path("./spec/support/**/*.rb")].each { |f| require f }

require "database"
require "schema"

Mobility::Test::Database.connect
at_exit {ActiveRecord::Base.connection.disconnect!}

require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before :each do
    DatabaseCleaner.start
    Mobility.locale = :en
  end
  config.after :each do
    DatabaseCleaner.clean
  end

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :active_record
    end
  end

  config.include(Shoulda::Matchers::ActiveModel, type: :model)
end
