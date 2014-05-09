# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'notifiable/gcm/spacialdb/version'

Gem::Specification.new do |spec|
  spec.name          = "notifiable-gcm-spacialdb"
  spec.version       = Notifiable::Gcm::Spacialdb::VERSION
  spec.authors       = ["Kamil Kocemba", "Matt Brooke-Smith"]
  spec.email         = ["kamil@futureworkshops.com", "matt@futureworkshops.com"]
  spec.homepage      = "http://www.futureworkshops.com"
  spec.description   = "Plugin to use GCM with Notifiable-Rails"
  spec.summary       = "Plugin to use GCM with Notifiable-Rails"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "notifiable-rails", ">=0.19.0"
  spec.add_dependency "gcm", "~> 0.0.6"
 
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1.1"
  spec.add_development_dependency "rspec", "~> 2.14.1"
  spec.add_development_dependency "simplecov", "~> 0.8.2"
  spec.add_development_dependency "simplecov-rcov", "~> 0.2.3"
  spec.add_development_dependency "sqlite3", "~> 1.3.8"
  spec.add_development_dependency "database_cleaner", "~> 1.2.0"
  spec.add_development_dependency "webmock", "~> 1.17.1"
  
end
