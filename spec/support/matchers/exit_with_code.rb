# frozen_string_literal: true
RSpec::Matchers.define :exit_with_code do |exp_code|
  actual = nil

  match do |block|
    begin
      block.call
    rescue SystemExit => e
      actual = e.status
    end
    actual && actual == exp_code
  end

  failure_message do
    "expected block to call exit(#{exp_code}) but exit" +
      (actual.nil? ? " not called" : "(#{actual}) was called")
  end

  failure_message_when_negated do
    "expected block not to call exit(#{exp_code})"
  end

  description do
    "expect block to call exit(#{exp_code})"
  end

  supports_block_expectations
end
