# frozen_string_literal: true
module Collectif

  class Emitter

    include EventEmitter
    attr_accessor :events

    WILDCARD = :all

    def initialize
      @events = []
    end

    def broadcast(payload)
      emittable_event_names(payload.with_indifferent_access).each do |emittable_event_name|
        emit(emittable_event_name, payload)
      end
    end

    private

    def emittable_event_names(payload)
      [
        event_name(payload),
        [event_name(payload), event_version(payload)].join(":"),
        WILDCARD
      ]
    end

    def event_name(payload)
      payload[:meta].try(:[], :name)
    end

    def event_version(payload)
      payload[:meta].try(:[], :version)
    end

  end

end
