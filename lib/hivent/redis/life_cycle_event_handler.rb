# frozen_string_literal: true
module Hivent

  module Redis

    class LifeCycleEventHandler

      # Invoked when a consumer worker starts and registers events and partion count.
      #
      # parameters:
      #   client_id: name of the application
      #   events: array of hashes for the registered events ([{ name: "my:event", version: 1 }, ...])
      #   partition_count: number of partitions registered for this application
      def application_registered(client_id, events, partition_count)
        # do nothing
      end

      # Invoked when an event has successfully been processed by all registered handlers
      #
      # parameters:
      #   event_name: name of the processed event
      #   event_version: version of the processed event
      #   payload: payload of the processed event
      def event_processing_succeeded(event_name, event_version, payload)
        # do nothing
      end

      # Invoked when processing an event failed. Either the payload could not be parsed as JSON or the payload did not
      # contain all required information or an application error happend while processing in one of the registered
      # handlers.
      #
      # parameters:
      #   exception: the exception that occurred
      #   payload: the parsed payload or nil if event payload was invalid JSON
      #   raw_payload: the original unparsed payload (String)
      #   dead_letter_queue_name: name of the dead letter queue this event has been sent to
      def event_processing_failed(exception, payload, raw_payload, dead_letter_queue_name)
        # do nothing
      end

    end

  end

end
