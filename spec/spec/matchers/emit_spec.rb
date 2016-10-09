# frozen_string_literal: true
require 'spec_helper'

describe Hivent::Spec::Matchers do

  subject do
    Hivent::Spec::Signal.new(signal).emit(payload, version: version, cid: cid)
  end

  let(:signal)      { 'my:signal' }
  let(:payload)     { { foo: 'bar' } }
  let(:version)     { 1 }
  let(:cid)         { SecureRandom.hex }

  describe '#emit' do

    it 'checks if an event was emitted' do
      expect { subject }.to emit(signal)
    end

    it 'checks if an event was emitted with a given version' do
      expect { subject }.to emit(signal, version: version)
    end

    it 'checks if an event was emitted with a given cid' do
      expect { subject }.to emit(signal, cid: cid)
    end

    it 'checks if an event was not emitted' do
      expect { subject }.not_to emit('other:signal')
    end

    it 'checks if an event was not emitted with a given version' do
      expect { subject }.not_to emit(signal, version: 2)
    end

    it 'checks if an event was not emitted with a given cid' do
      expect { subject }.not_to emit(signal, cid: 'does-not-match')
    end

    it 'checks if an event was emitted with a given payload' do
      expect { subject }.to emit(signal).with(payload)
    end

    it 'checks if an event was not emitted with a given payload' do
      expect { subject }.not_to emit(signal).with(bar: 'baz')
    end

    context 'when the subject emits multiple signals' do
      subject do
        Hivent::Spec::Signal.new(signal).emit({ bar: 'baz' }, version: version)
        Hivent::Spec::Signal.new(signal).emit(payload, version: version)
        Hivent::Spec::Signal.new(signal).emit({ foo: 'other' }, version: version)
      end

      it 'checks if an event was emitted' do
        expect { subject }.to emit(signal)
      end

      it 'checks if an event was emitted with a given payload' do
        expect { subject }.to emit(signal).with(payload)
      end
    end

  end
end
