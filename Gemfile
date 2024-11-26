source 'https://rubygems.org'

# Specify your gem's dependencies in mobility.gemspec
gemspec

orm, orm_version = ENV['ORM'], ENV['ORM_VERSION']

group :development, :test do
  case orm
  when 'active_record'
    orm_version ||= '7.0'
    case orm_version
    when '6.1', '7.0', '7.1', '7.2', '8.0'
      gem 'activerecord', "~> #{orm_version}.0"
    when 'edge'
      git 'https://github.com/rails/rails.git', branch: 'main' do
        gem 'activerecord'
        gem 'activesupport'
      end
    else
      raise ArgumentError, 'Invalid ActiveRecord version'
    end
  when 'sequel'
    orm_version ||= '5'
    case orm_version
    when '5'
      gem 'sequel', "~> #{orm_version}.0"
    else
      raise ArgumentError, 'Invalid Sequel version'
    end
  when nil, ''
  else
    raise ArgumentError, "Invalid ORM: #{orm}"
  end

  gem 'allocation_stats' if ENV['FEATURE'] == 'performance'

  if ENV['FEATURE'] == 'rails'
    gem 'rails'
    gem 'generator_spec', '~> 0.9.4'
  end

  platforms :ruby do
    gem 'guard-rspec'
    gem 'pry-byebug'
    case ENV['DB']
    when 'sqlite3'
      if orm == 'active_record' && orm_version < '5.2'
        gem 'sqlite3', '~> 1.3.13'
      elsif orm == 'active_record' && orm_version >= '8.0'
        gem 'sqlite3', '>= 2.1.0'
      else
        gem 'sqlite3', '~> 1.5.0'
      end
    when 'mysql'
      gem 'mysql2'
    when 'postgres'
      if orm == 'active_record' && orm_version < '5.0'
        gem 'pg', '< 1.0'
      else
        gem 'pg'
      end
    end
  end
end

group :benchmark do
  gem "benchmark-ips"
end
