# frozen_string_literal: true
require "spec_helper"

describe Hivent::Redis::Consumer do

  let(:consumer)         { described_class.new(redis, service_name, consumer_name, life_cycle_event_handler) }
  let(:redis)            { Redis.new(url: REDIS_URL) }
  let(:service_name)     { "a_service" }
  let(:consumer_name)    { "a_consumer" }
  let(:life_cycle_event_handler) { double("Hivent::LifeCycleEventHandler").as_null_object }

  after :each do
    redis.flushall

    Hivent.emitter.off
  end

  describe "#queues" do
    def balance(consumers)
      # 1. Marks every consumer as "alive"
      # 2. Resets every consumer
      # 3. Distributes partitions evenly
      3.times do
        consumers.each(&:queues)
      end
    end

    before :each do
      redis.set("#{service_name}:partition_count", partition_count)
    end

    context "with a single consumer" do
      subject { consumer.queues }

      let(:partition_count) { 2 }

      it "returns all available partitions" do
        expect(subject.length).to eq(partition_count)
      end
    end

    context "with two consumers and two partitions" do
      let(:consumer1)       { described_class.new(redis, service_name, "#{consumer_name}1", life_cycle_event_handler) }
      let(:consumer2)       { described_class.new(redis, service_name, "#{consumer_name}2", life_cycle_event_handler) }
      let(:partition_count) { 2 }

      context "when only one consumer is alive" do
        before :each do
          # Hearbeat from first consumer,
          # marking it as "alive"
          consumer1.queues
        end

        it "assigns all available partitions to the living consumer" do
          distribution = [consumer1.queues, consumer2.queues]

          expect(distribution.map(&:length)).to eq([2, 0])
        end

        describe "balancing" do
          it "resets the first consumer for rebalancing" do
            # Marks consumer 1 as alive, assigning all partitions
            consumer1.queues
            # Marks consumer 2 as alive, assigning 0 partitions to
            # start rebalancing
            consumer2.queues

            # Assigns 0 partitions to finish resetting
            expect(consumer1.queues.length).to eq(0)
          end

          it "assigns half the partitions after reset" do
            # Fully resets
            consumer1.queues
            consumer2.queues
            consumer1.queues

            # Distributes partitions across consumers
            expect(consumer2.queues.length).to eq(1)
          end

          it "rebalances partitions across both consumers" do
            consumer1.queues
            consumer2.queues
            consumer1.queues
            consumer2.queues

            # Distributes partitions across consumers
            expect(consumer1.queues.length).to eq(1)
          end

          context "when one of the consumers dies" do
            before :each do
              stub_const("#{described_class}::CONSUMER_TTL", 50)

              balance([consumer1, consumer2])
              count = 0

              while count <= 2
                consumer2.queues
                count += 1

                sleep described_class::CONSUMER_TTL.to_f / 1000
              end
            end

            it "assigns those consumer's partitions to another consumer" do
              expect(consumer2.queues.length).to eq(2)
            end
          end
        end
      end

      context "when both consumers are alive" do
        subject do
          [consumer1.queues, consumer2.queues]
        end

        before :each do
          balance([consumer1, consumer2])
        end

        it "returns all available partitions" do
          expect(subject.map(&:length)).to eq([1, 1])
        end
      end
    end

    context "with more consumers than partitions" do
      subject do
        [consumer1.queues, consumer2.queues]
      end

      let(:consumer1)       { described_class.new(redis, service_name, "#{consumer_name}1", life_cycle_event_handler) }
      let(:consumer2)       { described_class.new(redis, service_name, "#{consumer_name}2", life_cycle_event_handler) }
      let(:partition_count) { 1 }

      before :each do
        balance([consumer1, consumer2])
      end

      it "returns all available partitions" do
        expect(subject.map(&:length)).to eq([1, 0])
      end
    end

    context "with fewer consumers than partitions" do
      subject do
        [consumer1.queues, consumer2.queues]
      end

      let(:consumer1)       { described_class.new(redis, service_name, "#{consumer_name}1", life_cycle_event_handler) }
      let(:consumer2)       { described_class.new(redis, service_name, "#{consumer_name}2", life_cycle_event_handler) }
      let(:partition_count) { 3 }

      before :each do
        balance([consumer1, consumer2])
      end

      it "returns all available partitions" do
        expect(subject.map(&:length)).to eq([2, 1])
      end
    end

  end

  describe "#consume" do
    subject { consumer.consume }

    let(:partition_count) { 1 }
    let(:event) do
      {
        payload: { foo: "bar" },
        meta: {
          name: 'my:event',
          version: 1,
          event_uuid: SecureRandom.hex
        }
      }
    end
    let(:event_name_with_version) do
      "#{event[:meta][:name]}:#{event[:meta][:version]}"
    end
    let(:producer) { Hivent::Redis::Producer.new(redis) }

    before :each do
      redis.set("#{service_name}:partition_count", partition_count)
      redis.sadd(event[:meta][:name], service_name)

      producer.write(event[:meta][:name], event.to_json, 0)
    end

    context "when there are items ready to be consumed" do

      it "emits the item with indifferent access" do
        Hivent.emitter.on(event[:meta][:name]) do |received|
          expect(received[:payload][:foo]).to eq("bar")
          expect(received["payload"]["foo"]).to eq("bar")
        end

        subject
      end

      it "emits the item with name only and name with version" do
        counter = 0
        Hivent.emitter.on(event_name_with_version) do |_|
          counter += 1
        end
        Hivent.emitter.on(event[:meta][:name]) do |_|
          counter += 1
        end

        expect { subject }.to change { counter }.by(2)
      end

      it "removes the item from the queue" do
        subject

        expect(redis.llen("#{service_name}:0").to_i).to eq(0)
      end

      it "notifies life cycle event handler about the processed event" do
        expect(life_cycle_event_handler).to receive(:event_processing_succeeded)
          .with(event[:meta][:name], event[:meta][:version], event.with_indifferent_access)
        subject
      end

      context "when several items are produced" do
        let(:event2) { { foo: "bar" }.merge(event) }

        before :each do
          producer.write(event2[:meta][:name], event2.to_json, 0)
        end

        it "consumes all events in the order they were produced" do
          events = []
          Hivent.emitter.on(event_name_with_version) do |event|
            events << event
          end

          2.times { consumer.consume }

          expect(events).to eq([event, event2].map(&:with_indifferent_access))
        end
      end

      context "when processing fails" do

        let(:dead_letter_queue) { "#{service_name}:0:dead_letter" }

        before :each do
          Hivent.emitter.on(event_name_with_version) do |_|
            raise "something went wrong!"
          end
        end

        it "puts the item into a dead letter queue" do
          expect { subject }.to change { redis.llen(dead_letter_queue) }.by(1)
        end

        it "notifies life cycle event handler about the error" do
          expect(life_cycle_event_handler).to receive(:event_processing_failed)
            .with(instance_of(RuntimeError), event.with_indifferent_access, event.to_json, dead_letter_queue)
          subject
        end
      end

    end

    context "when there are no items ready to be consumed" do
      before :each do
        allow(Kernel).to receive(:sleep)

        redis.ltrim("#{service_name}:0", 1, -1)
      end

      it "sleeps for a little while" do
        subject
        expect(Kernel).to have_received(:sleep).with(described_class::SLEEP_TIME.to_f / 1000)
      end
    end

    describe "Wildcard event consumption" do
      before :each do
        redis.set("#{service_name}:partition_count", partition_count)
        redis.sadd("*", service_name)

        producer.write("some_event_name", { foo: "bar", meta: { name: "some_event_name" } }.to_json, 0)
      end

      it "consumes all events" do
        counter = 0
        Hivent.emitter.on(Hivent::Emitter::WILDCARD) do |_|
          counter += 1
        end

        expect { subject }.to change { counter }.by(1)
      end
    end
  end

  describe "#run!" do
    subject { Thread.new { consumer.run! } }

    let(:partition_count) { 2 }

    before :each do
      redis.set("#{service_name}:partition_count", partition_count)

      allow(consumer).to receive(:consume)
    end

    it "processes items" do
      thread = subject

      sleep 0.1

      thread.kill

      expect(consumer).to have_received(:consume).at_least(:once)
    end

  end

  describe "#stop!" do

    let(:partition_count) { 2 }

    before :each do
      redis.set("#{service_name}:partition_count", partition_count)
    end

    it "stops processing" do
      thread = Thread.new do
        consumer.run!
      end

      sleep 0.1

      consumer.stop!

      # nil is returned if timeout expires
      expect(thread.join(2)).to eq(thread)
    end

  end

end
