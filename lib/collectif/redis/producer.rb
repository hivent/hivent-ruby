# frozen_string_literal: true
module Collectif

  module Redis

    class Producer

      include Collectif::Redis::Extensions

      LUA_PRODUCER = File.expand_path("../lua/producer.lua", __FILE__)

      def initialize(redis)
        @redis = redis
      end

      def write(name, payload, partition_key)
        script(LUA_PRODUCER, name, payload, partition_key)
      end

    end

  end

end
