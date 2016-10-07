# frozen_string_literal: true
module Collectif

  class AbstractSignal

    attr_reader :name, :producer, :client_id

    def initialize(name)
      @name        = name
      @producer    = nil
      @client_id   = Collectif.config.client_id
    end

    def emit(payload, version:, cid: nil, key: nil)
      build_message(payload, cid, version).tap do |message|
        send_message(message, partition_key(key, message), version)
      end
    end

    def receive(version: nil, &block)
      Collectif.emitter.on(event_name(version), &block)
      Collectif.emitter.events << { name: name, version: version }
    end

    private

    def partition_key(key, message)
      key = key || message[:payload].to_json

      Zlib.crc32(key)
    end

    def send_message(_message, _key, _version)
      raise NotImplementedError
    end

    def build_message(payload, cid, version)
      {
        payload: payload,
        meta: meta_data(cid, version)
      }
    end

    def meta_data(cid, version)
      {
        event_uuid: SecureRandom.hex,
        name:       name,
        version:    version,
        cid:        (cid || SecureRandom.hex),
        producer:   client_id,
        created_at: Time.now.utc
      }
    end

    def event_name(version = nil)
      return Emitter::WILDCARD if name.to_sym == :*

      version ? "#{name}:#{version}" : name
    end

  end

end
