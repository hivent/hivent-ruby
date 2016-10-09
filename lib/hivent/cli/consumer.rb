# frozen_string_literal: true
require "socket"
require "fileutils"
require "pathname"
require "timeout"

module Hivent

  module CLI

    class Consumer

      def self.run!(args)
        new(args).run!
      end

      def initialize(options)
        @options = options
      end

      def run!
        configure
        register_service

        worker_name = "#{Socket.gethostname}:#{Process.pid}"
        @worker = Hivent::Redis::Consumer.new(@redis, @service_name, worker_name, @life_cycle_event_handler)

        @worker.run!
      end

      private

      def configure
        # use load instead of require to allow multiple runs of this method in specs
        load @options[:require]

        @service_name             = Hivent::Config.client_id
        @partition_count          = Hivent::Config.partition_count
        @life_cycle_event_handler = Hivent::Config.life_cycle_event_handler ||
                                      Hivent::LifeCycleEventHandler.new
        @events                   = Hivent.emitter.events
        @redis                    = Hivent::Redis.redis
      end

      def register_service
        # TODO: cleanup unused events for this service from the registry
        @redis.set("#{@service_name}:partition_count", @partition_count)

        @events.each do |event|
          @redis.sadd(event[:name], @service_name)
        end

        @life_cycle_event_handler.application_registered(@service_name, @events.deep_dup, @partition_count)
      end

    end

  end

end
