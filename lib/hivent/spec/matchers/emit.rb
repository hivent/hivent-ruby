# frozen_string_literal: true
module Hivent

  module Spec

    module Matchers

      class Emit

        def initialize(name, meta)
          @name = name
          @meta = meta
        end

        def emitted?
          before = signals.length

          yield

          signals.length > before
        end

        def emitted_with_payload?(payload)
          before = signals_with_payload(payload).length

          yield

          signals_with_payload(payload).length > before
        end

        def signals
          messages
            .lazy
            .select { |signal| signal[:name] == @name }
            .select do |signal|
              @meta.all? do |key, value|
                !value.present? ||
                value == signal[:message][:meta][key]
              end
            end
            .to_a
        end

        def signals_with_payload(payload)
          signals.select { |signal| deep_include?(signal[:message][:payload], payload) }
        end

        private

        def messages
          Signal.messages
        end

        def deep_include?(hash, sub_hash)
          sub_hash.keys.all? do |key|
            if hash.has_key?(key) && sub_hash[key].is_a?(Hash) && hash[key].is_a?(Hash)
              deep_include?(hash[key], sub_hash[key])
            else
              hash[key] == sub_hash[key]
            end
          end
        end

      end

    end

  end

end

RSpec::Matchers.define :emit do |name, meta = {}|
  matcher = Hivent::Spec::Matchers::Emit.new(name, meta)

  match do |actual|
    if actual.is_a?(Proc)
      if payload.present?
        matcher.emitted_with_payload?(payload, &actual)
      else
        matcher.emitted?(&actual)
      end
    end
  end

  chain :with, :payload

  failure_message do |_actual|
    message = %{expected to have emitted a signal with name "#{name}"}

    unless meta.empty?
      message += ", meta #{meta.inspect}"
    end

    if payload.present?
      message += " and payload #{payload.inspect}"
    end

    message
  end

  failure_message_when_negated do |_actual|
    message = %{expected not to have emitted a signal with name "#{name}"}

    unless meta.empty?
      message += ", meta #{meta.inspect}"
    end

    if payload.present?
      message += " and payload #{payload.inspect}"
    end

    message
  end

  supports_block_expectations
end
