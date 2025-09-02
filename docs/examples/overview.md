# Examples Overview

This section provides comprehensive, runnable examples that demonstrate BunnyFarm's capabilities. Each example includes complete code, setup instructions, and explanation of concepts.

## Available Examples

### 🚀 [Simple Producer/Consumer](simple-producer-consumer.md)
Perfect for getting started. Shows the basic patterns of message creation, publishing, and consumption.

**What you'll learn:**
- Basic message class creation
- Publishing messages
- Setting up consumers
- Message routing

**Use cases:**
- Background job processing
- Simple task queues
- Event notifications

---

### 📦 [Order Processing Workflow](order-processing.md)
A comprehensive e-commerce order processing system with multiple steps, error handling, and workflow management.

**What you'll learn:**
- Complex message workflows
- Multi-step processing
- Error handling and recovery
- State transitions
- Success/failure tracking

**Use cases:**
- E-commerce order processing
- Multi-step business workflows
- Complex validation chains
- Payment processing

---

### ⏰ [Task Scheduler](task-scheduler.md)  
Advanced example showing scheduled task execution, retry logic, and failure recovery patterns.

**What you'll learn:**
- Delayed message processing
- Retry mechanisms with exponential backoff
- Dead letter queue handling
- Monitoring and alerting
- Batch processing

**Use cases:**
- Scheduled report generation
- Recurring maintenance tasks
- Email campaigns
- Data synchronization

---

### 🌍 [Real World Examples](real-world.md)
Production-ready examples from real applications showing advanced patterns and best practices.

**What you'll learn:**
- Production configuration
- Monitoring and logging
- Performance optimization
- Error tracking
- Deployment patterns

**Use cases:**
- Microservice communication
- Event-driven architecture
- Data pipeline processing
- System integration

## Getting Started with Examples

### Prerequisites

Before running any examples, ensure you have:

1. **BunnyFarm installed**: `gem install bunny_farm`
2. **RabbitMQ running**: Local or remote instance
3. **Ruby 2.5+**: Compatible Ruby version

### Environment Setup

Set up your environment variables:

```bash
export AMQP_HOST=localhost
export AMQP_VHOST=/
export AMQP_PORT=5672
export AMQP_USER=guest
export AMQP_PASS=guest
export AMQP_EXCHANGE=bunny_farm_examples
export AMQP_QUEUE=example_queue
export AMQP_ROUTING_KEY='#'
export AMQP_APP_NAME=example_app
```

### Running Examples

Each example includes:

1. **Complete source code** - Copy-paste ready
2. **Setup instructions** - Step-by-step guide
3. **Expected output** - What you should see
4. **Troubleshooting** - Common issues and solutions
5. **Variations** - Alternative implementations

## Example Structure

All examples follow a consistent structure:

```
example_name/
├── README.md           # Setup and usage instructions
├── message_class.rb    # Message definition
├── producer.rb         # Message publisher
├── consumer.rb         # Message processor
└── config.rb          # Configuration (if needed)
```

## Architecture Patterns

The examples demonstrate key architectural patterns:

### Producer-Consumer Pattern
```ruby
# Producer
message = OrderMessage.new
message[:order_id] = 12345
message.publish('process')

# Consumer  
BunnyFarm.manage # Process incoming messages
```

### Workflow Pattern
```ruby
def process_order
  validate_order
  return unless successful?
  
  charge_payment  
  return unless successful?
  
  ship_order
  return unless successful?
  
  send_confirmation
end
```

### Retry Pattern
```ruby
def risky_operation
  retries = 0
  begin
    perform_operation
    success!
  rescue => e
    retries += 1
    if retries < 3
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      failure("Failed after 3 attempts: #{e.message}")
    end
  end
end
```

## Testing Examples

Each example includes test scenarios:

### Unit Testing
```ruby
# Test message behavior
message = OrderMessage.new
message[:order_id] = 123
message.validate_order

assert message.successful?
```

### Integration Testing
```ruby
# Test end-to-end flow
producer.publish_order(order_data)
consumer.process_next_message
assert_order_processed(order_data[:id])
```

## Common Patterns

### Configuration Management
```ruby
BunnyFarm.config do
  case ENV['RAILS_ENV']
  when 'production'
    env 'production'  
    bunny_file 'config/rabbitmq.yml'
  when 'development'
    # Use defaults
  end
end
```

### Error Handling
```ruby
def safe_operation
  begin
    risky_work
    success!
  rescue SpecificError => e
    failure("Known issue: #{e.message}")
  rescue StandardError => e
    failure("Unexpected error: #{e.message}")
  end
  
  successful?
end
```

### Logging and Monitoring
```ruby
def tracked_operation
  Rails.logger.info "Starting operation for #{@items[:id]}"
  
  result = perform_operation
  
  if successful?
    Rails.logger.info "Operation completed successfully"
  else
    Rails.logger.error "Operation failed: #{errors.join(', ')}"
  end
  
  result
end
```

## Performance Considerations

The examples include performance best practices:

- **Connection pooling** for high-throughput scenarios
- **Batch processing** for efficiency
- **Memory management** for long-running consumers
- **Queue configuration** for optimal performance

## Deployment Examples

Learn how to deploy BunnyFarm applications:

- **Docker containers** with proper configuration
- **Kubernetes** deployment manifests
- **Systemd services** for traditional servers
- **Cloud deployment** patterns

## Next Steps

Choose an example that matches your use case:

- **New to BunnyFarm?** Start with [Simple Producer/Consumer](simple-producer-consumer.md)
- **Building workflows?** Check out [Order Processing](order-processing.md)
- **Need scheduling?** See [Task Scheduler](task-scheduler.md)
- **Going to production?** Review [Real World Examples](real-world.md)