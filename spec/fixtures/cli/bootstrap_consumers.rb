# frozen_string_literal: true
Hivent.configure do |config|
  config.backend         = :redis
  config.endpoint        = REDIS_URL
  config.partition_count = 2
  config.client_id       = "test"
end
