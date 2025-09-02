# Instance Methods

BunnyFarm message instances provide a rich set of methods for data access, state management, and message operations.

## Data Access Methods

### Hash-like Access
```ruby
message = OrderMessage.new

# Get values
order_id = message[:order_id]
customer_name = message[:customer][:name]

# Set values
message[:order_id] = 12345
message[:customer] = { name: "John", email: "john@example.com" }
```

### Field Introspection
```ruby
# Get all field keys
keys = message.keys  # => [:order_id, :customer, :items]

# Check if field exists
has_customer = message.respond_to?(:[]) && message[:customer]

# Get field count
field_count = message.keys.length
```

## State Management

### Success/Failure Tracking
```ruby
def process_order
  validate_data
  return unless successful?
  
  charge_payment
  return unless successful?
  
  update_inventory
  success!  # Mark as successful
end

# Check state
if message.successful?
  puts "Order processed successfully"
else
  puts "Order failed: #{message.errors.join(', ')}"
end
```

### Error Management
```ruby
def validate
  failure("Order ID required") unless @items[:order_id]
  failure("Invalid email") unless valid_email?(@items[:email])
  
  # Check error state
  if failed?
    puts "Validation errors: #{errors.join(', ')}"
  else
    success!
  end
end
```

## Message Operations

### Publishing
```ruby
# Publish message
message.publish('process')  # Routing key: MessageClass.process

# Check if publish succeeded
if message.successful?
  puts "Message published successfully"
else
  puts "Publish failed: #{message.errors.join(', ')}"
end
```

### Serialization
```ruby
# Convert to JSON
json_string = message.to_json
puts json_string
# => {"order_id":12345,"customer":{"name":"John"}}

# Get raw payload (if received message)
original_json = message.payload
```

## Utility Methods

### Inspection and Debugging
```ruby
# Inspect message contents
puts message.inspect

# Pretty print for debugging
puts JSON.pretty_generate(message.to_hash)
```

### Cloning and Copying
```ruby
# Create copy with same data
new_message = message.class.new
message.keys.each { |key| new_message[key] = message[key] }

# Publish copy with different action
new_message.publish('different_action')
```