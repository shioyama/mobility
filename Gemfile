source 'https://rubygems.org'

# Specify your gem's dependencies in mobility.gemspec
gemspec

group :development, :test do
  if ENV['ORM'] == 'active_record'
    if ENV['RAILS_VERSION'] == '5.1'
      gem 'activerecord', '>= 5.1', '< 5.2'
    elsif ENV['RAILS_VERSION'] == '4.2'
      gem 'activerecord', '>= 4.2.6', '< 5.0'
    else
      gem 'activerecord', '>= 5.0', '< 5.1'
    end
    gem "generator_spec", '~> 0.9.4'
  elsif ENV['ORM'] == 'sequel'
    gem 'sequel', '>= 4.46.0'
  end

  platforms :ruby do
    gem 'guard-rspec'
    gem 'pry-byebug'
    gem 'sqlite3'
    gem 'mysql2', '~> 0.3.10'
    gem 'pg'
  end
end
