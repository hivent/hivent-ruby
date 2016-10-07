# Collectif

An event stream implementation that aggregates facts about your application.

## Configuration

### Redis Backend

```ruby
Collectif.configure do |config|
  config.backend :redis
  config.redis_endpoint "redis://localhost:6379/0"    # Redis endpoint
  config.partition_count 4                      # number of partions this application (identified by client_id)
                                                      # should read from
  config.redis_life_cycle_event_handler MyHandler.new # handler for consumption life cycle events
  config.client_id "my_app_name"                      # unique identifier for this application
end
```

## Usage

### Receive

Receiving works on an instance of a `Signal`. For each event received, the given block will be executed once.
You may either specify a version to receive or decide to receive all events for that signal regardless of their version.

```ruby
signal = Collectif::Signal.new("model_name:created")

# Handle all events for this signal
signal.receive do |event|
  # Do something with the event
  # event['payload'] contains the payload
  # event['meta'] contains information about the event
end

# Handle version 2 events for this signal
signal.receive(version: 2) do |event|
  # Do something with the event
  # event['payload'] contains the payload
  # event['meta'] contains information about the event
end
```

#### Wildcard signals

You can receive all events as well by using the `*` wildcard. Partial wildcards (such as `my_event:*`) are not supported at this time.

```ruby
signal = Collectif::Signal.new("*")

# Handle all events
signal.receive do |event|
  # Do something with the event
  # event['payload'] contains the payload
  # event['meta'] contains information about the event
end
```

#### Using with a Redis Backend

To receive events using the Redis backend a consumer process needs to be started using the provided CLI.

Start the consumer:

```bash
bundle exec collectif-receiver start -r app/events.rb
```

For more details on the available options see:

```bash
bundle exec collectif-receiver --help
bundle exec collectif-receiver start --help
```

##### Daemonization
The library does not offer any options to daemonize or parallelize your consumers. You are encouraged to use other tools such as [Foreman](https://ddollar.github.io/foreman/) and [Upstart](http://upstart.ubuntu.com) to achieve this.

With these two tools, you can set up a `Procfile` for the consumer:

```
consumer: bundle exec collectif-receiver start -r app/events.rb
```

And then use Foreman's `export` feature to convert it to an upstart job:

```bash
foreman export upstart -a myapp -m consumer=4 -u myuser /etc/init

service myapp start
```

This will start 4 consumer processes running under the `myuser` user. The processes will be daemonized and monitored by upstart.
If your consumers need environment variables, Foreman can [pick them up from a `.env` file](https://ddollar.github.io/foreman/#ENVIRONMENT) placed next to your `Procfile`:

```
APP_ENV=production
REDIS_URL=redis://something:6379
```

##### Callbacks for Life Cycle Events

To add error reporting or logging of consumed events you can configure an handler that is invoked by the consumer when certain lifecycle events occur.
To implement this handler create a class that inherits from [`Collectif::Redis::LifeCycleEventHandler`](lib/collectif/redis/life_cycle_event_handler.rb) and overwrite one or more of it's methods.

```ruby
class MyHandler < Collectif::Redis::LifeCycleEventHandler

  def application_registered(client_id, events, partition_count)
    # log info to logging service
  end

  def event_processing_succeeded(event_name, event_version, payload)
    # log event processing
  end

  def event_processing_failed(exception, payload, raw_payload, dead_letter_queue_name)
    # report to some exception notification service
  end

end
```

The handler needs to be configured in the gem's configuration block. The default handler ignores all life cycle events.

### Emit

You can use any name to identify your signals.

All signals are versioned. The version has to be specified as the second parameter of `emit` and will be part of the events meta data.

```ruby
Collectif::Signal.new("model_name:created").emit({ key: "value" }, version: 1)
# => Signal name is added as meta attribute "name"
```

#### Meta Data

Each emitted event will automatically be enriched with meta data containing the correlation ID (`cid`), the `producer` of the event (the `client_id` provided in the configuration block) and the `created_at` timestamp.

The event name and version will be added to the events meta data.

##### Correlation ID

To pass in a correlation ID (e.g. from a previously consumed message) use:

```ruby
cid = event['meta']['cid']
Collectif::Signal.new("model_name:created").emit({ key: "value" }, version: 1, cid: cid)
```

#### Keyed Messages

Sometimes it's required to pass a key alongside the message that is used to assign the message to a specific partition / shard (which ensures order of events within this partition).

The key can be defined in two different ways. Either by passing a key pattern when the signal is created:

```ruby
signal = Collectif::Signal.new("model_name:created", ["constant_string", :key_in_payload])
signal.emit({ key_in_payload: "value" })
```

or by passing the key when emitting the message (the key pattern will be ignored in this case):

```ruby
signal = Collectif::Signal.new("model_name:created")
signal.emit({ key: "value" }, key: "my_custom_key")
```

## Run the Tests

The test suite requires a running Redis server (default: `redis://localhost:6379/15`). To point to a different Redis pass in an environment variable when starting the tests.

```ruby
REDIS_URL=redis://path_to_redis:port/database bundle exec rspec
```

## Test Helpers

To help you write awesome tests, an RSpec helper is provided. To use it, require 'collectif/rspec' before running your test suite:

```ruby
# in spec_helper.rb

require 'collectif/rspec'
```

### Matchers

#### Emit

Test whether a signal has been emitted. Optionally, you can define a version.

```ruby
expect { a_method }.to emit('a:signal')
expect { another_method }.not_to emit('another:signal')
expect { another_method }.to emit('a:signal', version: 2)
```

You may also assert whether a signal was emitted with a given payload.
This matcher asserts that the signal's payload contains the given hash.

```ruby
expect { subject }.to emit(:event_name).with({ foo: 'bar' })
```
