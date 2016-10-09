# frozen_string_literal: true
require 'spec_helper'

describe Hivent do

  let(:client_id)  { "client_id" }

  describe "Configuration" do

    context "when configuring with an unsupported backend" do
      it "raises an UnsupportedOption Error" do
        expect {
          Hivent.configure do |config|
            config.backend = :unsupported
          end
        }.to raise_error(
          Hivent::Config::Options::UnsupportedOptionError,
          "Unsupported value :unsupported for option :backend"
        )
      end
    end

    context "when configuring with an empty client_id" do
      it "raises an UnsupportedOption Error" do
        expect {
          Hivent.configure do |config|
            config.client_id = nil
          end
        }.to raise_error(
          Hivent::Config::Options::UnsupportedOptionError,
          "Unsupported value nil for option :client_id"
        )
      end
    end

    context "when configuring with a non-integer partition_count" do
      it "raises an UnsupportedOption Error" do
        expect {
          Hivent.configure do |config|
            config.partition_count = "foo"
          end
        }.to raise_error(
          Hivent::Config::Options::UnsupportedOptionError,
          "Unsupported value \"foo\" for option :partition_count"
        )
      end
    end

    context "when configuring with a partition_count smaller than 1" do
      it "raises an UnsupportedOption Error" do
        expect {
          Hivent.configure do |config|
            config.partition_count = 0
          end
        }.to raise_error(
          Hivent::Config::Options::UnsupportedOptionError,
          "Unsupported value 0 for option :partition_count"
        )
      end
    end

    describe "accessing Configured values" do

      before :each do
        Hivent.configure do |config|
          config.client_id = client_id
        end
      end

      subject { Hivent::Config }

      let(:client_id)  { "an_id" }

      its(:client_id)  { is_expected.to eq(client_id) }

    end

  end

  describe "Event consumption" do
    subject { Hivent.emitter.emit "my_signal:1", increase: increase }

    let(:increase)  { 5 }

    after :each do
      Hivent.emitter.remove_listener "my_signal:1"
    end

    it "consumes events" do
      counter = 0
      Hivent.emitter.on "my_signal:1" do |data|
        counter += data[:increase]
      end

      expect { subject }.to change { counter }.by(increase)
    end

  end

end
