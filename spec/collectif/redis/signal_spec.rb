# frozen_string_literal: true
require 'spec_helper'

describe Collectif::Redis::Signal do

  let(:signal) do
    Collectif::Redis::Signal.new(name)
  end

  let(:name)         { "my_topic" }
  let(:client_id)    { "client_id" }
  let(:version)      { 5 }

  before :each do
    Collectif.configure do |config|
      config.backend :redis
      config.client_id client_id
    end
  end

  describe "#emit" do

    subject { signal.emit(payload, version: version, cid: cid, key: key) }

    let(:payload)      { { key: "value" } }
    let(:cid)          { nil }
    let(:key)          { SecureRandom.hex }
    let(:redis_client) { Redis.new(url: REDIS_URL) }
    let(:producer)     { Collectif::Redis::Producer.new(redis_client) }

    before :each do
      allow(Redis).to receive(:new).and_return(redis_client)
      allow(Collectif::Redis::Producer).to receive(:new).with(redis_client).and_return(producer)
    end

    after :each do
      redis_client.flushall
    end

    context "when no consuming services are configured" do
      it "does not send the message" do
        expect { subject }.not_to change { redis_client.keys }
      end

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when an exception is raised" do
      let(:max_tries)   { 2 }
      let(:wait_period) { 0.5 }

      before :each do
        stub_const("Collectif::Redis::Signal::MAX_TRIES", max_tries)
        stub_const("Collectif::Redis::Signal::SLEEP", wait_period)
      end

      it "retries sending the message after a wait period" do
        tries = 0

        expect(producer).to receive(:write).exactly(max_tries).times do |_message|
          tries += 1

          if tries < max_tries
            raise Redis::CommandError.new
          end
        end

        subject
      end
    end

    context "when a consuming service is configured" do
      let(:service_name)    { "some_service" }
      let(:partition_count) { 1 }

      before :each do
        redis_client.sadd(name, service_name)
        redis_client.set("#{service_name}:partition_count", partition_count)
      end

      it "creates a list containing the message" do
        subject
        item = JSON.parse(redis_client.lindex("#{service_name}:0", -1))

        expect(item["payload"]).to eq(payload.with_indifferent_access)
      end

      context "when configured with more than one partition" do
        let(:partition_count) { 2 }

        it "creates a message in only one of the partitions" do
          subject
          items = Array.new(partition_count) do |n|
            redis_client.lindex("#{service_name}:#{n}", -1)
          end

          expect(items.compact.length).to eq(1)
        end

        describe "message distribution" do
          subject do
            repetitions.times do
              signal.emit(payload, version: version, cid: cid, key: SecureRandom.hex)
            end
          end

          let(:partition_count) { 4 }
          let(:repetitions)     { 1000 }
          let(:lists) do
            Array.new(partition_count) { |n| "#{service_name}:#{n}" }
          end
          let(:item_counts) do
            lists.map { |list| redis_client.llen(list) }
          end
          let(:sum) { item_counts.sum }

          it "publishes messages on all partitions" do
            subject
            expect(item_counts.all? { |count| count > 0 }).to be(true)
          end

          it "publishes all the messages emitted" do
            subject
            expect(sum).to be(repetitions)
          end
        end
      end

    end

    context "when multiple consuming services are configured" do
      let(:service_names)   { ["some_service", "other_service"] }
      let(:partition_count) { 1 }

      before :each do
        service_names.each do |service_name|
          redis_client.sadd(name, service_name)
          redis_client.set("#{service_name}:partition_count", partition_count)
        end
      end

      it "creates a list for each service containing the message" do
        subject
        payloads = service_names.map do |service_name|
          JSON.parse(redis_client.lindex("#{service_name}:0", -1))["payload"]
        end

        expect(payloads.uniq).to eq([payload.with_indifferent_access])
      end
    end
  end

end
