# frozen_string_literal: true
require 'redis'

module Collectif

  module Redis

    def self.redis
      @@redis ||= ::Redis.new(url: Collectif.config.redis_endpoint)
    end

  end

end
