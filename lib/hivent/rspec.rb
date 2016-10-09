# frozen_string_literal: true
require 'hivent/spec'

RSpec.configure do |config|
  config.include Hivent::Spec

  config.before :each do |_example|
    stub_const('Hivent::Signal', Hivent::Spec::Signal)
    Hivent::Spec::Signal.reset!
  end

end
