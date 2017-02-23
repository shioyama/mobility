# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mobility/version'

Gem::Specification.new do |spec|
  spec.name          = "mobility"
  spec.version       = Mobility::VERSION
  spec.authors       = ["Chris Salzberg"]
  spec.email         = ["chris@dejimata.com"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.summary       = %q{Pluggable Ruby translation framework}
  spec.description   = %q{Stores and retrieves localized data through attributes on a Ruby class, with flexible support for different storage strategies.}

#  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files        = Dir['{lib/**/*,[A-Z]*}']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'request_store', '~> 1.0'
  spec.add_dependency 'i18n', '>= 0.6.10'
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "database_cleaner", '~> 1.5.3'
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-its", "~> 1.2.0"
  spec.add_development_dependency 'yard', '~> 0.9.0'
end
