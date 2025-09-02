# Smart Routing

BunnyFarm's smart routing system automatically creates predictable routing keys based on your message classes and actions. This eliminates the need for manual routing configuration while maintaining full transparency and debuggability.

## How Smart Routing Works

### Routing Key Pattern

BunnyFarm uses a simple, predictable pattern for routing keys:

```
MessageClassName.action
```

**Examples:**
- `OrderMessage.process` 
- `EmailMessage.send`
- `ReportMessage.generate`
- `UserRegistrationMessage.create_account`

### Automatic Generation

When you publish a message, the routing key is automatically generated:

```ruby
class OrderMessage < BunnyFarm::Message
  actions :validate, :process, :ship
end

# Publishing automatically creates routing keys
message = OrderMessage.new
message.publish('validate')  # Routing key: OrderMessage.validate
message.publish('process')   # Routing key: OrderMessage.process
message.publish('ship')      # Routing key: OrderMessage.ship
```

## Routing Flow

### 1. Publisher Side

```ruby
# 1. Create message
order_msg = OrderMessage.new
order_msg[:order_id] = 12345

# 2. Publish with action
order_msg.publish('process')

# 3. BunnyFarm generates routing key: "OrderMessage.process"
# 4. Message sent to RabbitMQ with this routing key
```

### 2. RabbitMQ Routing

```
Publisher → Exchange → Queue(s) → Consumer(s)
            ↑
    Routes based on
    "OrderMessage.process"
```

### 3. Consumer Side

```ruby
# 1. Consumer receives message with routing key "OrderMessage.process"
# 2. BunnyFarm parses routing key → class: OrderMessage, action: process  
# 3. Message deserialized to OrderMessage instance
# 4. The 'process' method is called automatically

class OrderMessage < BunnyFarm::Message
  def process
    # This method is called automatically
    puts "Processing order #{@items[:order_id]}"
    success!
  end
end
```

## Exchange and Queue Configuration

### Topic Exchange

BunnyFarm typically uses RabbitMQ's **topic exchange** for flexible routing:

```ruby
BunnyFarm.config do
  exchange_name 'bunny_farm_exchange'
  exchange_type :topic  # Supports pattern matching
end
```

### Queue Bindings

Queues can bind to specific routing patterns:

```ruby
# Bind to all OrderMessage actions
queue.bind(exchange, routing_key: 'OrderMessage.*')

# Bind to specific actions only
queue.bind(exchange, routing_key: 'OrderMessage.process')

# Bind to all messages
queue.bind(exchange, routing_key: '#')

# Bind to all validation actions across message types
queue.bind(exchange, routing_key: '*.validate')
```

## Routing Patterns

### 1. Single Message Type, Single Action

**Use case:** Dedicated worker for specific operations

```ruby
# Worker specializes in order processing
BunnyFarm.config do
  queue_name 'order_processing'
  routing_key 'OrderMessage.process'
end

# Only processes OrderMessage.process
BunnyFarm.manage
```

### 2. Single Message Type, Multiple Actions

**Use case:** Worker handles all operations for one domain

```ruby
# Worker handles all order operations
BunnyFarm.config do
  queue_name 'order_worker'
  routing_key 'OrderMessage.*'  # All OrderMessage actions
end

class OrderMessage < BunnyFarm::Message
  actions :validate, :process, :ship, :cancel
  
  def validate; end    # Handled by order_worker
  def process; end     # Handled by order_worker
  def ship; end        # Handled by order_worker
  def cancel; end      # Handled by order_worker
end
```

### 3. Multiple Message Types, Specific Actions

**Use case:** Worker specializes in one type of operation across domains

```ruby
# Worker handles validation for all message types
BunnyFarm.config do
  queue_name 'validation_worker'
  routing_key '*.validate'  # All validation actions
end

# These would all be handled by validation_worker:
# OrderMessage.validate
# CustomerMessage.validate  
# ProductMessage.validate
```

### 4. Multiple Message Types, All Actions

**Use case:** General-purpose worker

```ruby
# Worker handles everything
BunnyFarm.config do
  queue_name 'general_worker'
  routing_key '#'  # All messages
end
```

## Advanced Routing Scenarios

### Priority Queues

Route urgent messages to high-priority queues:

```ruby
class UrgentOrderMessage < BunnyFarm::Message
  actions :process_immediately
end

# High-priority worker
BunnyFarm.config do
  queue_name 'urgent_orders'
  routing_key 'UrgentOrderMessage.*'
  queue_options do
    arguments 'x-max-priority' => 10
  end
end

# Regular priority worker
BunnyFarm.config do
  queue_name 'regular_orders'  
  routing_key 'OrderMessage.*'
end
```

### Geographic Routing

Route messages based on regions:

```ruby
class USOrderMessage < BunnyFarm::Message
  actions :process, :ship
end

class EUOrderMessage < BunnyFarm::Message
  actions :process, :ship
end

# US worker
BunnyFarm.config do
  queue_name 'us_orders'
  routing_key 'USOrderMessage.*'
end

# EU worker
BunnyFarm.config do
  queue_name 'eu_orders'
  routing_key 'EUOrderMessage.*'
end
```

### Load Balancing

Multiple workers can consume from the same queue:

```ruby
# Worker 1
BunnyFarm.config do
  app_id 'worker_1'
  queue_name 'order_processing'
  routing_key 'OrderMessage.process'
end

# Worker 2  
BunnyFarm.config do
  app_id 'worker_2'
  queue_name 'order_processing'  # Same queue
  routing_key 'OrderMessage.process'
end

# RabbitMQ automatically load balances between workers
```

## Routing Key Introspection

### Debugging Routing

Check what routing key will be generated:

```ruby
class OrderMessage < BunnyFarm::Message
  actions :process
end

message = OrderMessage.new
routing_key = "#{message.class.name}.process"
puts routing_key  # => "OrderMessage.process"
```

### Runtime Routing Information

Access routing information during processing:

```ruby
class OrderMessage < BunnyFarm::Message
  def process
    puts "Processing with routing key: #{self.class.name}.process"
    puts "Message class: #{self.class.name}"
    puts "Action: process"
    
    success!
  end
end
```

## Error Routing

### Dead Letter Queues

Failed messages can be routed to error queues:

```ruby
BunnyFarm.config do
  queue_name 'order_processing'
  routing_key 'OrderMessage.*'
  
  queue_options do
    arguments({
      'x-dead-letter-exchange' => 'failed_messages',
      'x-dead-letter-routing-key' => 'failed.OrderMessage'
    })
  end
end
```

### Retry Queues

Implement retry logic with delayed routing:

```ruby
class OrderMessage < BunnyFarm::Message
  def process
    begin
      perform_processing
      success!
    rescue RetryableError => e
      if retry_count < 3
        # Publish to retry queue with delay
        retry_message = self.class.new(@items)
        retry_message[:retry_count] = retry_count + 1
        retry_message.publish_delayed('process', delay: 30.seconds)
        success!  # Don't NACK original message
      else
        failure("Max retries exceeded: #{e.message}")
      end
    end
    
    successful?
  end
  
  private
  
  def retry_count
    @items[:retry_count] || 0
  end
end
```

## Monitoring and Debugging

### RabbitMQ Management UI

Use RabbitMQ's management interface to monitor routing:

1. **Exchanges tab** - See message routing statistics
2. **Queues tab** - Monitor queue depths and consumption rates
3. **Connections tab** - View active publishers and consumers

### Routing Metrics

Track routing patterns in your application:

```ruby
class OrderMessage < BunnyFarm::Message
  def process
    # Track routing metrics
    Metrics.increment("message.routed.#{self.class.name}.process")
    
    # Your processing logic
    perform_order_processing
    
    Metrics.increment("message.processed.#{self.class.name}.process")
    success!
  end
end
```

### Logging Routing Events

Log routing information for debugging:

```ruby
class OrderMessage < BunnyFarm::Message
  def process
    logger.info "Processing message",
                routing_key: "#{self.class.name}.process",
                message_id: @items[:order_id]
    
    # Processing logic
    success!
  end
end
```

## Best Practices

### 1. Predictable Naming

Use clear, consistent class and action names:

```ruby
# Good: Clear domain and action
class CustomerRegistrationMessage < BunnyFarm::Message
  actions :validate_email, :create_account, :send_welcome
end

# Avoid: Vague or abbreviated names
class CRM < BunnyFarm::Message
  actions :val, :cr8, :snd
end
```

### 2. Logical Grouping

Group related actions in the same message class:

```ruby
# Good: Related order operations
class OrderMessage < BunnyFarm::Message  
  actions :validate, :process_payment, :fulfill, :ship, :complete
end

# Avoid: Mixing unrelated operations
class MixedMessage < BunnyFarm::Message
  actions :process_order, :send_email, :backup_database, :clean_temp_files
end
```

### 3. Queue Design

Design queues around processing capabilities:

```ruby
# Good: Separate concerns
BunnyFarm.config do
  case worker_type
  when 'payment_processor'
    routing_key '*.process_payment'
  when 'email_sender'
    routing_key '*.send_email'
  when 'order_validator'
    routing_key 'OrderMessage.validate'
  end
end
```

### 4. Error Handling

Plan for routing errors:

```ruby
def process
  validate_message_structure
  return unless successful?
  
  perform_business_logic
  return unless successful?
  
  log_success
end

private

def validate_message_structure
  required_fields = [:order_id, :customer_id, :amount]
  missing = required_fields.select { |field| @items[field].nil? }
  
  failure("Missing required fields: #{missing.join(', ')}") if missing.any?
end
```

## Next Steps

Understanding smart routing enables you to:

- **[Configure](../configuration/overview.md)** routing for your specific needs
- **[Design message structures](../message-structure/overview.md)** that route effectively  
- **[Scale your architecture](../architecture/scaling.md)** with proper queue design
- **[Handle errors](error-handling.md)** with appropriate routing strategies