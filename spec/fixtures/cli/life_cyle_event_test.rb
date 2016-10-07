# frozen_string_literal: true
Collectif.configure do |config|
  config.backend :redis
  config.redis_endpoint REDIS_URL
  config.partition_count 2
  config.client_id "test"
  config.redis_life_cycle_event_handler MyHandler.new
end
