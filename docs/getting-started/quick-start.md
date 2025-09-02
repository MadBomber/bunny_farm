# Quick Start

This guide will get you up and running with BunnyFarm in just a few minutes. We'll create a simple message class, publish a message, and process it.

## Prerequisites

Before starting, make sure you have:

- [BunnyFarm installed](installation.md)
- RabbitMQ server running locally or accessible remotely
- Basic familiarity with Ruby

## Step 1: Create Your First Message Class

Create a file called `greeting_message.rb`:

```ruby
require 'bunny_farm'

class GreetingMessage < BunnyFarm::Message
  # Define the fields this message expects
  fields :name, :language
  
  # Define the actions this message can perform
  actions :send_greeting
  
  def send_greeting
    puts "Hello #{@items[:name]}! (in #{@items[:language]})"
    
    # Mark the message as successfully processed
    success!
    
    # Return true to ACK the message
    successful?
  end
end
```

## Step 2: Configure BunnyFarm

Create a simple configuration (or use environment variables):

```ruby
# Basic configuration using defaults
BunnyFarm.config do
  app_id 'greeting_app'
end
```

## Step 3: Publish a Message

Create a file called `publisher.rb`:

```ruby
require_relative 'greeting_message'

# Configure BunnyFarm
BunnyFarm.config do
  app_id 'greeting_publisher'
end

# Create a new message
message = GreetingMessage.new

# Set the message data
message[:name] = 'Alice'
message[:language] = 'English'

# Publish the message with the 'send_greeting' action
message.publish('send_greeting')

if message.successful?
  puts "Message published successfully!"
else
  puts "Failed to publish message: #{message.errors.join(', ')}"
end
```

## Step 4: Create a Consumer

Create a file called `consumer.rb`:

```ruby
require_relative 'greeting_message'

# Configure BunnyFarm
BunnyFarm.config do
  app_id 'greeting_consumer'
end

puts "Starting message consumer..."
puts "Press Ctrl+C to stop"

# Start processing messages (this will block)
BunnyFarm.manage
```

## Step 5: Run the Example

1. **Start the consumer** (in one terminal):
   ```bash
   ruby consumer.rb
   ```

2. **Publish a message** (in another terminal):
   ```bash
   ruby publisher.rb
   ```

You should see output like:

**Consumer terminal:**
```
Starting message consumer...
Press Ctrl+C to stop
Hello Alice! (in English)
```

**Publisher terminal:**
```
Message published successfully!
```

## Understanding What Happened

1. **Message Class**: `GreetingMessage` defines the structure and behavior
2. **Fields DSL**: `fields :name, :language` specifies expected data
3. **Actions DSL**: `actions :send_greeting` defines available operations
4. **Routing Key**: The message was routed using `GreetingMessage.send_greeting`
5. **JSON Serialization**: Data was automatically serialized/deserialized
6. **AMQP Flow**: Message traveled through RabbitMQ from publisher to consumer

## Next Steps

Now that you have a basic understanding, explore:

- **[Basic Concepts](basic-concepts.md)** - Understand BunnyFarm's architecture
- **[Message Structure](../message-structure/overview.md)** - Learn about the Fields and Actions DSL
- **[Configuration Options](../configuration/overview.md)** - Advanced configuration
- **[Examples](../examples/overview.md)** - More comprehensive examples

## Common Issues

### Connection Refused
If you see connection errors, ensure RabbitMQ is running:
```bash
# Check RabbitMQ status
sudo systemctl status rabbitmq-server

# Or for Docker
docker ps | grep rabbitmq
```

### Permission Denied
Make sure your AMQP credentials are correct in your environment variables or configuration.

### Messages Not Processing
Verify that your consumer is listening to the correct queue and routing key configuration.