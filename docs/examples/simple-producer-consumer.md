# Simple Producer/Consumer

Basic example showing message publishing and consumption.

## Producer
```ruby
message = GreetingMessage.new
message[:name] = 'World'
message.publish('greet')
```

## Consumer
```ruby
BunnyFarm.manage
```