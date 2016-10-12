# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hivent/version'

Gem::Specification.new do |spec|
  spec.name          = "hivent"
  spec.version       = Hivent::VERSION
  spec.authors       = ["Bruno Abrantes"]
  spec.email         = ["bruno@brunoabrantes.com"]
  spec.summary       = "An event stream implementation that aggregates facts about your application"
  spec.description   = ""
  spec.homepage      = "https://github.com/inf0rmer/hivent-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 5.0"
  spec.add_dependency "retryable", "~> 2.0"
  spec.add_dependency "redis", "~> 3.3"
  spec.add_dependency "emittr", "~> 0.1"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "rspec-its", "~> 1.2"
  spec.add_development_dependency "rspec-eventually", "~> 0.2"
  spec.add_development_dependency "pry-byebug", "~> 3.4"
  spec.add_development_dependency "simplecov", "~> 0.12"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.6"
  spec.add_development_dependency "rubocop", "~> 0.43"
  spec.add_development_dependency "gem-release", "~> 0.7"
  spec.add_development_dependency "rake", "~> 11.3"
end
