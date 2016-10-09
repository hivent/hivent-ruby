# frozen_string_literal: true
module Hivent

  module Signal

    # pretend Signal is a class so that using backends is transparent
    def self.new(*args)
      klass = "Hivent::#{Hivent::Config.backend.to_s.camelize}::Signal"
      klass.constantize.new(*args)
    end

  end

end
