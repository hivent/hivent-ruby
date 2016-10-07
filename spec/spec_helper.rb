# frozen_string_literal: true
require 'simplecov'

require 'rspec/its'
require 'pry'

require 'collectif'
require 'collectif/rspec'
require 'collectif/cli/runner'

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/support/**/*.rb").each { |f| require f }

REDIS_URL = ENV["REDIS_URL"].presence || "redis://localhost:6379/15"

RSpec.configure do |config|
  config.include STDOUTHelpers

  config.after :each do
    Collectif.configure {}
    Collectif::Redis.class_variable_set(:@@redis, nil)
  end
end
