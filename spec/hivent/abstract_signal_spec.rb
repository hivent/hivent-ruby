# frozen_string_literal: true
require 'spec_helper'

describe Hivent::AbstractSignal do

  class MySignal < Hivent::AbstractSignal

    private

    def send_message(message, key, version)
      # do nothing
    end

  end

  let(:signal) do
    MySignal.new(name)
  end
  let(:name)          { "my_signal" }
  let(:payload)       { { key: "value" } }
  let(:version)       { 1 }
  let(:cid)           { nil }
  let(:partition_key) { nil }
  let(:client_id)     { "my_client_id" }

  before :each do
    Hivent.configure do |config|
      config.backend :redis
      config.client_id client_id
    end
  end

  describe "#emit" do

    subject { signal.emit(payload, version: version, cid: cid, key: partition_key) }

    its([:meta]) { is_expected.to be_present }
    its([:payload]) { is_expected.to be_present }
    its([:payload, :key]) { is_expected.to eq("value") }

    context "contains meta data with" do

      context "when correlation ID is omitted" do
        its([:meta, :cid]) { is_expected.to be_present }
      end

      context "when correlation ID is passed" do
        let(:cid)          { "cid" }
        its([:meta, :cid]) { is_expected.to eq(cid) }
      end

      its([:meta, :producer])   { is_expected.to eq(client_id) }
      its([:meta, :created_at]) { is_expected.to be_present }
      its([:meta, :name])       { is_expected.to eq(name) }
      its([:meta, :version])    { is_expected.to eq(version) }
      its([:meta, :event_uuid]) { is_expected.to be_present }

    end

    context "when a key is provided" do
      let(:partition_key) { SecureRandom.hex }

      it "sends the message using the given key as the partition key" do
        expect(signal).to receive(:send_message).once
          .with(anything, Zlib.crc32(partition_key), anything)

        subject
      end
    end

    context "when a key is not provided" do
      let(:partition_key) { nil }

      it "sends the message using a partition key derived from the message" do
        allow(signal).to receive(:send_message).once
          .with(anything, Zlib.crc32(payload.to_json), anything)

        subject
      end
    end

  end

  describe "#receive" do
    after :each do
      Hivent.emitter.remove_listener name
      Hivent.emitter.events.clear
    end

    it "receives events for this signal with their payload" do
      emitted_payload  = { foo: "bar" }
      received_payload = nil

      signal.receive do |payload|
        received_payload = payload
      end

      Hivent.emitter.emit(name, emitted_payload)

      expect(received_payload).to equal(emitted_payload)
    end

    context "when a version is not specified" do
      let(:version) { nil }

      it "receives events transmitted using only the signal's name" do
        counter = 0

        signal.receive { counter += 1 }

        expect { Hivent.emitter.emit name }.to change { counter }.by(1)
      end

      it "stores the event in the consumer" do
        signal.receive {}
        expect(Hivent.emitter.events).to include(name: name, version: version)
      end

    end

    context "when a version is specified" do
      let(:version) { 2 }

      it "receives events transmitted using the signal's name and version" do
        counter = 0

        signal.receive(version: version) { counter += 1 }

        expect { Hivent.emitter.emit "#{name}:#{version}" }.to change { counter }.by(1)
      end

      it "stores the event in the consumer" do
        signal.receive(version: version) {}
        expect(Hivent.emitter.events).to include(name: name, version: version)
      end

    end

    context "with a wildcard signal" do
      let(:signal) do
        MySignal.new("*")
      end

      it "receives events for all signals signal with their payloads" do
        received_payloads = []

        signal.receive do |payload|
          received_payloads << payload
        end

        Hivent.emitter.emit(Hivent::Emitter::WILDCARD, foo: "bar")
        Hivent.emitter.emit(Hivent::Emitter::WILDCARD, foo: "baz")

        expect(received_payloads).to eq([{ foo: "bar" }, { foo: "baz" }])
      end

    end

  end

end
