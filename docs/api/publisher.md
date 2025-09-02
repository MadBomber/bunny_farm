# Publisher API

API for publishing messages to RabbitMQ.

## Publishing Messages
```ruby
message = OrderMessage.new
message.publish('process')
```