# frozen_string_literal: true
require "active_support"
require "active_support/core_ext"
require "retryable"
require "json"
require "event_emitter"

require "collectif/signal"
require "collectif/abstract_signal"
require "collectif/emitter"

require "collectif/redis/redis"
require "collectif/redis/extensions"
require "collectif/redis/signal"

require "collectif/redis/life_cycle_event_handler"
require "collectif/redis/consumer"

module Collectif

  SUPPORTED_BACKENDS = [:redis].freeze

  def self.configure
    @config = Config.new
    yield @config
  end

  def self.config
    @config || Config.new
  end

  def self.emitter
    @emitter ||= Emitter.new
  end

  class Config

    class UnsupportedBackendError < StandardError; end

    def initialize
      @client_id  = nil
      @middleware = {}
    end

    def backend(backend = nil)
      if backend
        raise UnsupportedBackendError unless SUPPORTED_BACKENDS.include?(backend.to_sym)
        @backend = backend.to_sym
      else
        @backend || :null
      end
    end

    def redis_endpoint(redis_endpoint = nil)
      @redis_endpoint = redis_endpoint || @redis_endpoint
    end

    def partition_count(partition_count = nil)
      @partition_count = partition_count || @partition_count
    end

    def redis_life_cycle_event_handler(redis_life_cycle_event_handler = nil)
      @redis_life_cycle_event_handler = redis_life_cycle_event_handler || @redis_life_cycle_event_handler
    end

    def client_id(client_id = nil)
      @client_id = client_id || @client_id
    end

    def to_hash
      {
        client_id:       client_id,
        backend:         backend,
        redis_endpoint:  redis_endpoint,
        partition_count: partition_count
      }
    end

  end

end
