# frozen_string_literal: true
require 'spec_helper'

describe Collectif::Spec::Signal do
  subject do
    described_class.new(name)
  end

  let(:name) { "my:signal" }

  describe "#emit" do
    subject { super().emit(payload, version: version) }

    let(:payload) { { foo: "bar" } }
    let(:version) { 1 }

    before :each do
      allow(Collectif.emitter).to receive(:emit)
    end

    it "emits that event on the wildcard channel" do
      expect(Collectif.emitter).to receive(:emit)
        .with(Collectif::Emitter::WILDCARD, hash_including(payload: payload))

      subject
    end

    it 'emits that event with the given name' do
      expect(Collectif.emitter).to receive(:emit).with(name, hash_including(payload: payload))

      subject
    end

    it 'emits that event with the given name and version' do
      expect(Collectif.emitter).to receive(:emit).with("#{name}:#{version}", hash_including(payload: payload))

      subject
    end

    context "with a Redis backend" do
      before :each do
        Collectif.configure do |config|
          config.backend :redis
          config.redis_life_cycle_event_handler life_cycle_event_handler
        end
      end

      let(:life_cycle_event_handler) { double }

      it "notifies life cycle event handler about the processed event" do
        expect(life_cycle_event_handler).to receive(:event_processing_succeeded)
          .with(name, version, hash_including(payload: payload))
        subject
      end

      context "when emitting fails" do

        let(:error) { StandardError.new("error") }

        before :each do
          allow(Collectif.emitter).to receive(:emit).and_raise(error)
        end

        it "notifies life cycle event handler about the error" do
          expect(life_cycle_event_handler).to receive(:event_processing_failed)
            .with(error, hash_including(payload: payload), kind_of(String), kind_of(String))
          subject
        end
      end
    end
  end
end
