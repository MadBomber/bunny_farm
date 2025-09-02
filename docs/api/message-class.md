# Message Class API Reference

The `BunnyFarm::Message` class is the foundation of the BunnyFarm library. All your message classes inherit from this base class to gain message processing capabilities.

## Class Definition

```ruby
class YourMessage < BunnyFarm::Message
  fields :field1, :field2, { nested: [:field3, :field4] }
  actions :action1, :action2
  
  def action1
    # Your processing logic
  end
end
```

## Class Methods

### `fields(*field_definitions)`

Defines the expected data structure for the message.

**Parameters:**
- `field_definitions` - Variable number of field definitions

**Field Definition Types:**

```ruby
# Simple fields
fields :name, :email, :age

# Nested objects  
fields { customer: [:name, :email, :phone] }

# Mixed definitions
fields :order_id, :total, 
       { customer: [:name, :email] },
       { items: [:product_id, :quantity, :price] }
```

**Example:**
```ruby
class OrderMessage < BunnyFarm::Message
  fields :order_id, :total,
         { customer: [:name, :email, :phone] },
         { billing_address: [:street, :city, :state, :zip] },
         { items: [:product_id, :quantity, :price] }
end
```

### `actions(*action_names)`

Defines the available actions (operations) for this message type.

**Parameters:**
- `action_names` - Variable number of action symbols

**Example:**
```ruby
class OrderMessage < BunnyFarm::Message
  actions :validate, :process_payment, :fulfill, :ship, :cancel
  
  def validate
    # Validation logic
  end
  
  def process_payment
    # Payment logic  
  end
end
```

**Routing Keys:**
Each action creates a routing key in the format: `MessageClassName.action`
- `OrderMessage.validate`
- `OrderMessage.process_payment`
- `OrderMessage.fulfill`

## Instance Methods

### Data Access

#### `[](key)`
Get a field value using hash-like syntax.

**Parameters:**
- `key` - Field name as symbol or string

**Returns:**
- Field value or `nil` if not set

**Example:**
```ruby
message = OrderMessage.new
value = message[:customer_name]
nested = message[:customer][:email]
```

#### `[]=(key, value)`
Set a field value using hash-like syntax.

**Parameters:**
- `key` - Field name as symbol or string  
- `value` - Value to set

**Example:**
```ruby
message[:customer_name] = "John Doe"
message[:customer] = { name: "John", email: "john@example.com" }
```

#### `keys`
Get all available field keys.

**Returns:**
- Array of field keys

**Example:**
```ruby
message.keys # => [:order_id, :customer, :items]
```

### State Management

#### `success!`
Mark the current operation as successful.

**Example:**
```ruby
def process_order
  # ... processing logic
  success!
end
```

#### `failure(error_message)`
Mark the current operation as failed with an error message.

**Parameters:**
- `error_message` - String describing the failure

**Example:**
```ruby
def process_payment  
  if payment_declined?
    failure("Payment was declined by bank")
  end
end
```

#### `successful?`
Check if the current operation was successful.

**Returns:**
- `true` if successful, `false` otherwise

**Example:**
```ruby
def process_order
  validate_order
  return unless successful?
  
  process_payment
  return unless successful?
  
  ship_order
end
```

#### `failed?`
Check if the current operation failed.

**Returns:**
- `true` if failed, `false` otherwise  

**Example:**
```ruby
if message.failed?
  puts "Processing failed: #{message.errors.join(', ')}"
end
```

#### `errors`
Get array of error messages accumulated during processing.

**Returns:**
- Array of error message strings

**Example:**
```ruby
def validate
  failure("Name is required") if @items[:name].blank?
  failure("Email is invalid") unless valid_email?(@items[:email])
end

# Later...
if message.failed?
  message.errors # => ["Name is required", "Email is invalid"]
end
```

### Message Operations

#### `publish(action)`
Publish the message with the specified action.

**Parameters:**
- `action` - Action name as string or symbol

**Returns:**
- `true` if published successfully, `false` otherwise

**Example:**
```ruby
message = OrderMessage.new
message[:order_id] = 12345
message[:customer] = { name: "John", email: "john@example.com" }

if message.publish('process')
  puts "Message published successfully"
else  
  puts "Failed to publish: #{message.errors.join(', ')}"
end
```

**Routing Key:**
The message will be routed using: `MessageClassName.action`

#### `to_json`
Convert the message data to JSON string.

**Returns:**
- JSON string representation of the message data

**Example:**
```ruby
message[:name] = "John"
message[:email] = "john@example.com"
json = message.to_json
# => '{"name":"John","email":"john@example.com"}'
```

## Instance Variables

### `@items`
Hash containing the validated and structured message data based on field definitions.

**Access:**
- Direct: `@items[:field_name]`
- Hash-like: `message[:field_name]`

### `@elements`
Hash containing the raw message data as received from the message broker.

### `@payload`
String containing the original JSON payload as received from RabbitMQ.

### `@errors`
Array containing error messages accumulated during processing.

## Action Method Implementation

When you define actions, you must implement corresponding methods:

```ruby
class OrderMessage < BunnyFarm::Message
  actions :validate, :process, :ship
  
  def validate
    # Validation logic here
    validate_customer_info
    validate_order_items
    validate_shipping_address
    
    # Mark as successful if no errors
    success! if errors.empty?
    
    # Return true for ACK, false for NACK
    successful?
  end
  
  def process
    # Processing logic
    charge_payment
    update_inventory
    
    if payment_successful? && inventory_updated?
      success!
    else
      failure("Order processing failed")
    end
    
    successful?
  end
  
  def ship
    # Shipping logic
    create_shipping_label
    notify_carrier
    send_tracking_info
    
    success!
    successful?
  end
  
  private
  
  def validate_customer_info
    failure("Customer name required") if @items[:customer][:name].blank?
    failure("Customer email required") if @items[:customer][:email].blank?
  end
  
  def charge_payment
    # Payment processing logic
  end
end
```

## Error Handling Patterns

### Basic Error Handling
```ruby
def risky_operation
  begin
    perform_external_call
    success!
  rescue ExternalServiceError => e
    failure("External service failed: #{e.message}")
  rescue StandardError => e
    failure("Unexpected error: #{e.message}")
  end
  
  successful?
end
```

### Validation with Multiple Errors
```ruby
def validate
  failure("Name required") if @items[:name].blank?
  failure("Email required") if @items[:email].blank?
  failure("Invalid email format") unless valid_email?
  
  success! if errors.empty?
  successful?
end
```

### Conditional Processing
```ruby  
def process_order
  validate_order
  return unless successful?
  
  authorize_payment  
  return unless successful?
  
  fulfill_order
  return unless successful?
  
  send_confirmation
end
```

## Best Practices

### 1. Always Return Success Status
Action methods should always return the result of `successful?`:

```ruby
def my_action
  # ... processing logic
  success! # or failure(...)
  successful? # Always return this
end
```

### 2. Use Descriptive Error Messages
Provide clear, actionable error messages:

```ruby
# Good
failure("Customer email format is invalid: #{email}")

# Avoid  
failure("Invalid input")
```

### 3. Implement Idempotent Operations
Make operations safe to retry:

```ruby
def charge_payment
  return success! if already_charged?
  
  # Perform charge only if not already done
  result = payment_gateway.charge(@items[:amount])
  
  if result.success?
    success!
  else
    failure("Payment failed: #{result.error}")
  end
  
  successful?
end
```

### 4. Keep Actions Focused
Each action should have a single, clear responsibility:

```ruby
# Good: Focused actions
actions :validate_order, :process_payment, :ship_order

# Avoid: Overly broad actions
actions :handle_order # Too generic
```