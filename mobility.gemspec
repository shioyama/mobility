# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mobility/version'

Gem::Specification.new do |spec|
  spec.name          = "mobility"
  spec.version       = Mobility::VERSION
  spec.authors       = ["Chris Salzberg"]
  spec.email         = ["chris@dejimata.com"]

  spec.required_ruby_version = '>= 2.3.7'

  spec.summary       = %q{Pluggable Ruby translation framework}
  spec.description   = %q{Stores and retrieves localized data through attributes on a Ruby class, with flexible support for different storage strategies.}

  spec.homepage     = 'https://github.com/shioyama/mobility'
  spec.license       = "MIT"

  spec.files        = Dir['{lib/**/*,[A-Z]*}']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'request_store', '~> 1.0'
  spec.add_dependency 'i18n', '>= 0.6.10', '< 2'
  spec.add_development_dependency "database_cleaner", '~> 1.5', '>= 1.5.3'
  spec.add_development_dependency "rake", '~> 12', '>= 12.2.1'
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'yard', '~> 0.9.0'

  spec.cert_chain = ["certs/shioyama.pem"]
  spec.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/
end
