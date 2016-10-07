# frozen_string_literal: true
require 'spec_helper'

describe Collectif do

  let(:client_id)  { "client_id" }

  before :each do
    Collectif.configure do |config|
      config.client_id client_id
    end
  end

  describe ".config" do

    subject { Collectif.config }

    let(:client_id)  { "an_id" }

    its(:client_id)  { is_expected.to eq(client_id) }

  end

  describe "Event consumption" do
    subject { Collectif.emitter.emit "my_signal:1", increase: increase }

    let(:increase)  { 5 }

    after :each do
      Collectif.emitter.remove_listener "my_signal:1"
    end

    it "consumes events" do
      counter = 0
      Collectif.emitter.on "my_signal:1" do |data|
        counter += data[:increase]
      end

      expect { subject }.to change { counter }.by(increase)
    end

  end

end
