source 'https://rubygems.org'

# Specify your gem's dependencies in mobility.gemspec
gemspec

group :development, :test do
  if ENV['ORM'] == 'active_record'
    gem 'activerecord', '>= 5.0', '< 5.1'
    gem "generator_spec", '~> 0.9.3'
  end

  if ENV['ORM'] == 'sequel'
    gem 'sequel', '>= 4.0.0', '< 5.0'
    #gem 'sequel_polymorphic', git: "https://github.com/jackdempsey/sequel_polymorphic", ref: "v0.3.0"
    gem 'sequel_polymorphic', git: "https://github.com/shioyama/sequel_polymorphic", branch: "pass_blocks_to_super"
  end

  platforms :ruby do
    gem 'guard-rspec'
    gem 'pry-byebug'
    gem 'sqlite3'
    gem 'mysql2', '~> 0.3.10'
    gem 'pg'
  end
end
