# frozen_string_literal: true
require 'hivent/spec'

RSpec.configure do |config|
  config.include Hivent::Spec

  config.before :each do |_example|
    Hivent::Spec::Signal.reset!
  end

end
