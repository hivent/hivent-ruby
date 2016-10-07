# frozen_string_literal: true
require 'zlib'
require 'collectif/redis/producer'

module Collectif

  module Redis

    class Signal < AbstractSignal

      MAX_TRIES   = 4
      SLEEP       = ->(n) { (n**4) * 0.01 }

      def initialize(*args)
        super

        @producer = Producer.new(redis)
      end

      private

      def send_message(message, key, _version)
        Retryable.retryable(tries: MAX_TRIES, sleep: SLEEP) do
          producer.write(name, message.to_json, key)
        end
      end

      def redis
        Collectif::Redis.redis
      end

    end

  end

end
