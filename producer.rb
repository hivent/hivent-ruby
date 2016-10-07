lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "./lib/collectif"

Collectif.configure do |config|
  config.backend :redis
  config.redis_endpoint "redis://localhost:32769/0"
  config.partition_count 2
  config.client_id "producer"
end

loop do
  Collectif::Signal.new("test:signal").emit({ foo: "bar" }, version: rand(1..3))

  sleep rand(1..5)
end
