lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "./lib/collectif"

Collectif.configure do |config|
  config.backend :redis
  config.redis_endpoint "redis://localhost:32769/0"
  config.partition_count 2
  config.client_id "test"
end

Collectif::Signal.new("test:signal").receive(version: 1) do |event|
  puts "received signal at version 1"
  puts event.inspect
end

Collectif::Signal.new("test:signal").receive(version: 2) do |event|
  puts "received signal at version 2"
  puts event.inspect
end

Collectif::Signal.new("test:signal").receive do |event|
  puts "received signal at an unspecified version"
  puts event.inspect
end
