# frozen_string_literal: true
require "spec_helper"

describe Collectif::CLI::Consumer do

  let(:consumer) { Collectif::CLI::Consumer.new(options) }
  let(:options) { {} }

  let(:life_cycle_event_handler) { double("Collectif::Redis::LifeCycleEventHandler").as_null_object }
  let(:require_file) { File.expand_path("../../../fixtures/cli/bootstrap_consumers.rb", __FILE__) }

  before :each do
    allow(Collectif::Redis::LifeCycleEventHandler).to receive(:new).and_return(life_cycle_event_handler)
  end

  describe "#run!" do

    subject                     { silence { consumer.run! } }
    let(:options)               { { require: require_file } }
    let(:redis)                 { Redis.new(url: REDIS_URL) }
    let(:service_name)          { "test" }
    let(:partition_count)       { 2 }
    let(:redis_consumer_double) { double("Collectif::Redis::Consumer").as_null_object }

    before :each do
      allow(Collectif::Redis::Consumer).to receive(:new).and_return(redis_consumer_double)
    end

    after :each do
      redis.flushall
      Collectif.emitter.events.clear
    end

    it "registers the partition count for the service" do
      expect { subject }.to change {
        redis.get("#{service_name}:partition_count")
      }.from(nil).to(partition_count.to_s)
    end

    it "registers events for the service" do
      Collectif.emitter.events.push({ name: "my:event", version: 1 }, name: "my:event2")
      expect { subject }.to change {
        [redis.smembers("my:event"), redis.smembers("my:event2")].flatten
      }.from([]).to([service_name, service_name])
    end

    it "notifies life cycle event handler about registration of events" do
      events = [{ name: "my:event", version: 1 }, { name: "my:event2" }]
      Collectif.emitter.events.push(*events)
      expect(life_cycle_event_handler).to receive(:application_registered).with(service_name, events, partition_count)
      subject
    end

    it "starts the consumer" do
      double = double().as_null_object

      allow(Collectif::Redis::Consumer).to receive(:new)
        .with(instance_of(Redis), service_name, "#{Socket.gethostname}:#{Process.pid}", life_cycle_event_handler)
        .and_return(double)

      subject
      expect(double).to have_received(:run!).once
    end

  end

end
