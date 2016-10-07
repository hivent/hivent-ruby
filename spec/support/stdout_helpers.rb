# frozen_string_literal: false
module STDOUTHelpers

  def with_captured_stdout(&_block)
    original_stdout = $stdout
    $stdout = StringIO.new('', 'w')
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def silence(&_block)
    result = nil
    begin
      original_stdout = $stdout
      $stdout = StringIO.new('', 'w')
      result = yield
    ensure
      $stdout = original_stdout
    end
    result
  end

end
