source 'https://rubygems.org'

# Specify your gem's dependencies in mobility.gemspec
gemspec

group :development, :test do
  if ENV['ORM'] == 'active_record'
    if ENV['RAILS_VERSION'] == '5.0'
      gem 'activerecord', '>= 5.0', '< 5.1'
    elsif ENV['RAILS_VERSION'] == '4.2'
      gem 'activerecord', '>= 4.2.6', '< 5.0'
    elsif ENV['RAILS_VERSION'] == '5.1'
      gem 'activerecord', '>= 5.1', '< 5.2'
    elsif ENV['RAILS_VERSION'] == 'latest'
      gem 'activerecord', '>= 6.0.0.beta1'
    else # Default is Rails 5.2
      gem 'activerecord', '>= 5.2.0', '< 5.3'
      gem 'railties', '>= 5.2.0.rc2', '< 5.3'
    end
    gem "generator_spec", '~> 0.9.4'
  elsif ENV['ORM'] == 'sequel'
    if ENV['SEQUEL_VERSION'] == '4'
      gem 'sequel', '>= 4.46.0', '< 5.0'
    else
      gem 'sequel', '>= 5.0.0', '< 6.0.0'
    end
  end

  gem 'allocation_stats' if ENV['TEST_PERFORMANCE']

  platforms :ruby do
    gem 'guard-rspec'
    gem 'pry-byebug'
    gem 'sqlite3', '~> 1.3.6'
    gem 'mysql2', '~> 0.4.9'
    gem 'pg', '< 1.0'
  end
end

group :benchmark do
  gem "benchmark-ips"
end
