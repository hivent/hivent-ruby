# frozen_string_literal: true
module Hivent

  module Redis

    class Consumer

      include Hivent::Redis::Extensions

      LUA_CONSUMER = File.expand_path("../lua/consumer.lua", __FILE__)
      # In milliseconds
      SLEEP_TIME   = 200
      CONSUMER_TTL = 1000

      def initialize(redis, service_name, name, life_cycle_event_handler)
        @redis                    = redis
        @service_name             = service_name
        @name                     = name
        @stop                     = false
        @life_cycle_event_handler = life_cycle_event_handler
      end

      def run!
        consume while !@stop
      end

      def stop!
        @stop = true
      end

      def queues
        script(LUA_CONSUMER, @service_name, @name, CONSUMER_TTL)
      end

      def consume
        to_process = items

        to_process.each do |(queue, item)|
          payload = nil
          begin
            payload = JSON.parse(item).with_indifferent_access

            Hivent.emitter.broadcast(payload)

            @life_cycle_event_handler.event_processing_succeeded(event_name(payload), event_version(payload), payload)
          rescue => e
            @redis.lpush(dead_letter_queue_name(queue), item)

            @life_cycle_event_handler.event_processing_failed(e, payload, item, dead_letter_queue_name(queue))
          end

          @redis.rpop(queue)
        end

        Kernel.sleep(SLEEP_TIME.to_f / 1000) if to_process.empty?
      end

      private

      def items
        queues
          .map    { |queue| [queue, @redis.lindex(queue, -1)] }
          .select { |(_queue, item)| item }
      end

      def event_name(payload)
        payload["meta"].try(:[], "name")
      end

      def event_version(payload)
        payload["meta"].try(:[], "version")
      end

      def dead_letter_queue_name(queue)
        "#{queue}:dead_letter"
      end

    end

  end

end
