# frozen_string_literal: true
require "spec_helper"

describe Collectif::Redis::LifeCycleEventHandler do

  subject { silence { consumer.run! } }

  let(:consumer) { Collectif::CLI::Consumer.new(require: require_file) }
  let(:require_file) { File.expand_path("../../../fixtures/cli/life_cyle_event_test.rb", __FILE__) }
  let(:redis_consumer_double) { double("Collectif::Redis::Consumer").as_null_object }

  let(:redis) { Redis.new(url: REDIS_URL) }
  let(:handler_class) { Class.new(described_class) }

  let(:event) { { name: "my:event", version: 1 } }

  before :each do
    stub_const("MyHandler", handler_class) # MyHandler is used in require file
    allow(Collectif::Redis::Consumer).to receive(:new).and_return(redis_consumer_double)
  end

  after :each do
    redis.flushall
    Collectif.emitter.events.clear
  end

  it "notifies custom life cycle event handler about registration of events" do
    Collectif.emitter.events.push(event)
    expect_any_instance_of(handler_class).to receive(:application_registered)
    subject
  end

  it "passes life cycle event handler to redis consumer" do
    expect(Collectif::Redis::Consumer).to receive(:new).with(anything, anything, anything, instance_of(handler_class))
    subject
  end

end
