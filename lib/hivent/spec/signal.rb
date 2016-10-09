# frozen_string_literal: true
require 'hivent/abstract_signal'

module Hivent

  module Spec

    class Signal < AbstractSignal

      def self.reset!
        @store = []
      end

      def self.messages
        @store ||= []
      end

      def initialize(*args)
        super
      end

      def messages
        self.class.messages
      end

      def emit(_payload, version:, cid: nil, key: nil)
        super.tap do |message|
          begin
            Hivent.emitter.broadcast(message)

            report_success(name, version, message)
          rescue => e
            report_failure(e, message)
          end
        end
      end

      private

      def life_cycle_event_handler
        Hivent.config.redis_life_cycle_event_handler
      end

      def report_success(name, version, message)
        life_cycle_event_handler.try(:event_processing_succeeded, name, version, message)
      end

      def report_failure(e, message)
        life_cycle_event_handler.try(:event_processing_failed, e, message, message.to_json, "queue")
      end

      def send_message(message, _key, _version)
        messages << { name: @name, message: message }
      end

    end

  end

end
