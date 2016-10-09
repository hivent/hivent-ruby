# frozen_string_literal: true
require "hivent/life_cycle_event_handler"
require "hivent/config/options"

module Hivent

  module Config

    SUPPORTED_BACKENDS = [:redis].freeze

    extend self
    extend Options

    option :client_id, validate: ->(value) { value.present? }
    option :backend, validate: ->(value) { SUPPORTED_BACKENDS.include?(value.to_sym) }
    option :endpoint
    option :partition_count, default: 1, validate: ->(value) { value.is_a?(Integer) && value.positive? }
    option :life_cycle_event_handler, default: LifeCycleEventHandler.new

  end

end
