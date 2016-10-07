# frozen_string_literal: true
require 'collectif/spec'

RSpec.configure do |config|
  config.include Collectif::Spec

  config.before :each do |_example|
    Collectif::Spec::Signal.reset!
  end

end
