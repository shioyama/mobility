source 'https://rubygems.org'

# Specify your gem's dependencies in mobility.gemspec
gemspec

group :development, :test do
  if ENV['ORM'] == 'active_record'
    if ENV['RAILS_VERSION'] == '5.0'
      gem 'activerecord', '>= 5.0', '< 5.1'
    elsif ENV['RAILS_VERSION'] == '4.2'
      gem 'activerecord', '>= 4.2.6', '< 5.0'
    else
      gem 'activerecord', '>= 5.1', '< 5.2'
    end
    gem "generator_spec", '~> 0.9.4'
  elsif ENV['ORM'] == 'sequel'
    if ENV['SEQUEL_VERSION'] < '4.46'
      gem 'sequel', '>= 4.41.0', '< 4.46.0'
    else
      gem 'sequel', '>= 4.46.0'
    end
  end

  platforms :ruby do
    gem 'guard-rspec'
    gem 'pry-byebug'
    gem 'sqlite3'
    gem 'mysql2', '~> 0.3.10'
    gem 'pg'
  end
end
