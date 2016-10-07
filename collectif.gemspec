# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'collectif/version'

Gem::Specification.new do |spec|
  spec.name          = "collectif"
  spec.version       = Collectif::VERSION
  spec.authors       = ["Bruno Abrantes"]
  spec.email         = ["bruno@brunoabrantes.com"]
  spec.summary       = 'An event stream implementation that aggregates facts about your application'
  spec.description   = ''
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"

  spec.add_dependency "activesupport", '>= 3.0'
  spec.add_dependency "retryable"
  spec.add_dependency "redis"
  spec.add_dependency "event_emitter"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency "rubocop"
end
