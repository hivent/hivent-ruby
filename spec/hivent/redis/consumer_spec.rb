require "spec_helper"

describe Hivent::Redis::Consumer do

  let(:consumer)         { described_class.new(redis, service_name, consumer_name, life_cycle_event_handler) }
  let(:redis)            { Redis.new(url: REDIS_URL) }
  let(:service_name)     { "a_service" }
  let(:consumer_name)    { "a_consumer" }
  let(:life_cycle_event_handler) { double("Hivent::Redis::LifeCycleEventHandler").as_null_object }

  before :each do
    stub_const("#{described_class}::CONSUMER_TTL", 1000)
  end

  after :each do
    Hivent.emitter.off
    redis.flushall

    Thread.list.each do |thread|
      thread.exit unless thread == Thread.current
    end
  end

  describe "#queues" do
    def balance(consumers)
      # 1. Marks every consumer as "alive"
      # 2. Resets every consumer
      # 3. Distributes partitions evenly
      consumers.map do |consumer|
        Thread.new { consumer.run! }
      end
    end

    before :each do
      redis.set("#{service_name}:partition_count", partition_count)
    end

    context "with a single consumer" do
      subject { consumer.queues }

      let(:partition_count) { 2 }

      before :each do
        Thread.new { consumer.run! }
        sleep 0.1
      end

      it "returns all available partitions" do
        expect { subject.length }.to eventually eq(partition_count)
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
          Thread.new { consumer1.run! }
          sleep 0.1
        end

        it "assigns all available partitions to the living consumer" do
          expect { [consumer1.queues, consumer2.queues].map(&:length) }.to eventually eq([2, 0])
        end

        describe "balancing" do
          it "assigns half the partitions after reset" do
            threads = []
            # Fully resets
            threads << Thread.new { consumer1.run! }
            sleep 0.1
            threads << Thread.new { consumer2.run! }
            sleep 0.1

            # Distributes partitions across consumers
            expect { consumer2.queues.length }.to eventually eq(1)
          end

          it "rebalances partitions across both consumers" do
            threads = []

            threads << Thread.new { consumer1.run! }
            sleep 0.1
            threads << Thread.new { consumer2.run! }
            sleep 0.1

            Thread.new { consumer1.stop! }
            Thread.new { consumer2.stop! }
            sleep 0.1

            threads << Thread.new { consumer1.run! }
            sleep 0.1
            threads << Thread.new { consumer2.run! }
            sleep 0.1

            # Distributes partitions across consumers
            expect { consumer1.queues.length }.to eventually eq(1)
          end

          context "when one of the consumers dies" do
            before :each do
              stub_const("#{described_class}::CONSUMER_TTL", 50)

              threads = balance([consumer1, consumer2])
              Thread.new { consumer1.stop! }
              threads.first.exit

              sleep described_class::CONSUMER_TTL.to_f / 1000
            end

            it "assigns those consumer's partitions to another consumer" do
              expect { consumer2.queues.length }.to eventually eq(2)
            end
          end
        end
      end

      context "when both consumers are alive" do
        before :each do
          balance([consumer1, consumer2])
        end

        it "returns all available partitions" do
          expect { [consumer1.queues, consumer2.queues].map(&:length) }.to eventually eq([1, 1])
        end
      end
    end

    context "with more consumers than partitions" do
      let(:consumer1)       { described_class.new(redis, service_name, "#{consumer_name}1", life_cycle_event_handler) }
      let(:consumer2)       { described_class.new(redis, service_name, "#{consumer_name}2", life_cycle_event_handler) }
      let(:partition_count) { 1 }

      before :each do
        balance([consumer1, consumer2])
      end

      it "returns all available partitions" do
        expect { [consumer1.queues, consumer2.queues].map(&:length) }.to eventually eq([1, 0])
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
        expect { [consumer1.queues, consumer2.queues].map(&:length) }.to eventually eq([2, 1])
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
      Thread.new { consumer.run! }
      sleep 0.1

      redis.set("#{service_name}:partition_count", partition_count)
      redis.sadd(event[:meta][:name], service_name)

      producer.write(event[:meta][:name], event.to_json, 0)
    end

    after :each do
      Thread.new { consumer.stop! }
      sleep 0.1
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
    let(:partition_count) { 2 }

    before :each do
      redis.set("#{service_name}:partition_count", partition_count)

      allow(consumer).to receive(:consume)

      stub_const("#{described_class}::CONSUMER_TTL", 10000)
    end

    it "starts its heartbeat" do
      thread = Thread.new { consumer.run! }

      sleep 1

      is_alive = redis.get("#{service_name}:#{consumer_name}:alive")

      thread.kill

      expect(is_alive).to be
    end

    it "processes items" do
      thread = Thread.new { consumer.run! }
      sleep 0.2

      expect(consumer).to have_received(:consume).at_least(:once)

      thread.kill
    end

  end

  describe "#stop!" do

    let(:partition_count) { 2 }

    before :each do
      redis.set("#{service_name}:partition_count", partition_count)
      stub_const("#{described_class}::CONSUMER_TTL", 10)
    end

    it "stops its heartbeat" do
      thread = Thread.new do
        consumer.run!
      end

      sleep 0.1

      consumer.stop!
      thread.kill

      sleep 0.2

      expect { redis.get("#{service_name}:#{consumer_name}:alive") }.to eventually be_nil
    end

    it "stops processing" do
      thread = Thread.new do
        consumer.run!
      end

      sleep 0.1

      consumer.stop!
      thread.kill

      # nil is returned if timeout expires
      expect(thread.join(2)).to eq(thread)
    end

  end

end
