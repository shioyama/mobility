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
    else
      # TODO: change to '>= 5.2.0.beta1, < 5.3'
      #   once dirty specs pass in 5.2.0.rc1
      gem 'activerecord', '5.2.0.beta2'
      gem 'railties', '5.2.0.beta2'
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
    gem 'sqlite3'
    gem 'mysql2', '~> 0.4.9'
    gem 'pg', '< 1.0'
  end
end

group :benchmark do
  gem "benchmark-ips"
end
