source 'https://rubygems.org'

# Specify your gem's dependencies in mobility.gemspec
gemspec

orm, orm_version = ENV['ORM'].split('-', 2)

group :development, :test do
  case orm
  when 'active_record'
    orm_version ||= '6.0' # default is 6.1
    case orm_version
    when '4.2'
      gem 'activerecord', '>= 4.2.6', '< 5.0'
    when '5.0'
      gem 'activerecord', '>= 5.0', '< 5.1'
    when '5.1'
      gem 'activerecord', '>= 5.1', '< 5.2'
    when '5.2'
      gem 'activerecord', '>= 5.2.0', '< 5.3'
      gem 'railties', '>= 5.2.0.rc2', '< 5.3'
    when '6.0'
      gem 'activerecord', '>= 6.0.0', '< 6.1'
    else
      raise ArgumentError, 'Invalid ActiveRecord version'
    end

    gem "generator_spec", '~> 0.9.4'
  when 'sequel'
    orm_version ||= '5'
    case orm_version
    when '4'
      gem 'sequel', '>= 4.46.0', '< 5.0'
    when '5'
      gem 'sequel', '>= 5.0.0', '< 6.0.0'
    else
      raise ArgumentError, 'Invalid Sequel version'
    end
  when nil # no ORM
  else
    raise ArgumentError, 'Invalid ORM'
  end

  gem 'allocation_stats' if ENV['TEST_PERFORMANCE']

  platforms :ruby do
    gem 'guard-rspec'
    gem 'pry-byebug'
    if orm == 'active_record' && orm_version < '5.2'
      gem 'sqlite3', '~> 1.3.13'
    else
      gem 'sqlite3', '~> 1.4.1'
    end
    gem 'mysql2', '~> 0.4.9'
    gem 'pg', '< 1.0'
  end
end

group :benchmark do
  gem "benchmark-ips"
end
