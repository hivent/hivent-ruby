module Collectif

  module Signal

    # pretend Signal is a class so that using backends is transparent
    def self.new(*args)
      klass = "Collectif::#{Collectif.config.backend.to_s.camelize}::Signal"
      klass.constantize.new(*args)
    end

  end

end
