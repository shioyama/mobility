source 'https://rubygems.org'

# Specify your gem's dependencies in mobility.gemspec
gemspec

orm, orm_version = ENV['ORM'], ENV['ORM_VERSION']

group :development, :test do
  case orm
  when 'active_record'
    orm_version ||= '6.0'
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
    when '6.1'
      git 'https://github.com/rails/rails.git' do
        gem 'activerecord'
        gem 'activesupport'
      end
    else
      raise ArgumentError, 'Invalid ActiveRecord version'
    end
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
  when nil, ''
  else
    raise ArgumentError, "Invalid ORM: #{orm}"
  end

  gem 'allocation_stats' if ENV['FEATURE'] == 'performance'

  if ENV['FEATURE'] == 'rails'
    gem 'rails', '>= 6.0.0', '< 6.1'
    gem 'generator_spec', '~> 0.9.4'
    gem 'sqlite3', '~> 1.4.1'
  end

  platforms :ruby do
    gem 'guard-rspec'
    gem 'pry-byebug'
    case ENV['DB']
    when 'sqlite3'
      if orm == 'active_record' && orm_version < '5.2'
        gem 'sqlite3', '~> 1.3.13'
      else
        gem 'sqlite3', '~> 1.4.1'
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
