# frozen_string_literal: true
require 'redis'

module Hivent

  module Redis

    def self.redis
      @@redis ||= ::Redis.new(url: Hivent.config.redis_endpoint)
    end

  end

end
