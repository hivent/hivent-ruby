# frozen_string_literal: true
require "active_support"
require "active_support/core_ext"
require "retryable"
require "json"
require "emittr"

require "hivent/config"

require "hivent/signal"
require "hivent/abstract_signal"
require "hivent/emitter"

require "hivent/redis/redis"
require "hivent/redis/extensions"
require "hivent/redis/signal"
require "hivent/life_cycle_event_handler"
require "hivent/redis/consumer"

module Hivent

  extend self

  def configure
    block_given? ? yield(Hivent::Config) : Hivent::Config
  end

  def self.emitter
    @emitter ||= Emitter.new
  end

end
