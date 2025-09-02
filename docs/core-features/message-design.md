# Message-Centric Design

BunnyFarm's core philosophy revolves around treating messages as first-class objects that encapsulate both data and behavior. This approach provides a clean, object-oriented way to handle background job processing.

## What is Message-Centric Design?

In traditional job queue systems, jobs are simple data structures passed to generic worker processes. BunnyFarm takes a different approach where each message type is a full Ruby class that defines:

- **Data structure** - What fields the message contains
- **Business logic** - What operations can be performed
- **Error handling** - How failures are managed
- **State management** - Success/failure tracking

## Benefits of Message Classes

### 1. Encapsulation
Related data and behavior stay together:

```ruby
class OrderMessage < BunnyFarm::Message
  # Data structure
  fields :order_id, :customer_email, :items
  
  # Business logic
  actions :validate, :process_payment, :ship
  
  def validate
    validate_order_data
    validate_customer_info
    success! if errors.empty?
  end
  
  def process_payment
    # Payment logic here
    success!
  end
end
```

### 2. Discoverability
Easy to understand what a message can do:

```ruby
# Clear interface
OrderMessage.new.respond_to?(:validate)    # => true
OrderMessage.new.respond_to?(:ship)        # => true
OrderMessage.new.respond_to?(:fly_rocket)  # => false
```

### 3. Testability
Individual message types can be unit tested:

```ruby
class TestOrderMessage < Minitest::Test
  def test_validation
    message = OrderMessage.new
    message[:order_id] = nil
    message.validate
    
    assert message.failed?
    assert_includes message.errors, "Order ID required"
  end
end
```

### 4. Type Safety
Ruby's class system provides structure:

```ruby
class OrderMessage < BunnyFarm::Message
  fields :order_id, :customer_email
  
  def validate
    failure("Order ID required") if @items[:order_id].nil?
    failure("Invalid email") unless valid_email?(@items[:customer_email])
  end
  
  private
  
  def valid_email?(email)
    email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  end
end
```

## Message Anatomy

Every BunnyFarm message has four key components:

### 1. Class Definition
Inherit from `BunnyFarm::Message`:

```ruby
class CustomerMessage < BunnyFarm::Message
  # Message definition
end
```

### 2. Fields DSL
Define the data structure:

```ruby
fields :name, :email, :phone,
       { address: [:street, :city, :state, :zip] },
       { preferences: [:newsletter, :marketing] }
```

### 3. Actions DSL
Define available operations:

```ruby
actions :register, :update_profile, :send_welcome_email
```

### 4. Action Methods
Implement the business logic:

```ruby
def register
  validate_customer_data
  return unless successful?
  
  create_account
  return unless successful?
  
  send_welcome_email
end
```

## Design Patterns

### Command Pattern
Each action is a command that can be executed:

```ruby
class ReportMessage < BunnyFarm::Message
  actions :generate, :email, :archive
  
  def generate
    # Generate report
    @report_data = create_report
    success!
  end
  
  def email
    # Email the report
    send_report_email(@report_data)
    success!
  end
end

# Usage
report = ReportMessage.new
report[:report_type] = 'monthly_sales'
report.publish('generate')  # Execute generate command
```

### State Machine Pattern
Messages can represent state transitions:

```ruby
class OrderMessage < BunnyFarm::Message
  actions :place_order, :confirm_payment, :ship_order, :complete_order
  
  def place_order
    @items[:status] = 'pending'
    validate_order
    success!
  end
  
  def confirm_payment
    return failure("Order not pending") unless @items[:status] == 'pending'
    
    @items[:status] = 'confirmed'
    process_payment
    success!
  end
end
```

### Template Method Pattern
Define common workflow structure:

```ruby
class ProcessingMessage < BunnyFarm::Message
  def process
    validate_input
    return unless successful?
    
    perform_work
    return unless successful?
    
    finalize_result
  end
  
  private
  
  # Subclasses override these methods
  def validate_input; raise NotImplementedError; end
  def perform_work; raise NotImplementedError; end  
  def finalize_result; success!; end
end

class OrderProcessingMessage < ProcessingMessage
  def validate_input
    failure("Invalid order") unless valid_order?
  end
  
  def perform_work
    charge_payment
    update_inventory
  end
end
```

## Message Lifecycle

Understanding the message lifecycle helps design better message classes:

### 1. Creation
```ruby
message = OrderMessage.new
message[:order_id] = 12345
message[:customer_email] = 'customer@example.com'
```

### 2. Publishing
```ruby
message.publish('validate') # Routing key: OrderMessage.validate
```

### 3. Consumption
```ruby
# Consumer receives message and calls validate method
def validate
  # Business logic
  success!
  successful? # Returns true for ACK
end
```

### 4. Acknowledgment
- `true` return → Message acknowledged (ACK)
- `false` return → Message rejected (NACK)

## Best Practices

### 1. Single Responsibility
Each message class should handle one domain:

```ruby
# Good: Focused on orders
class OrderMessage < BunnyFarm::Message
  actions :validate, :process, :ship
end

# Avoid: Too broad
class EverythingMessage < BunnyFarm::Message
  actions :process_order, :send_email, :update_inventory, :generate_report
end
```

### 2. Clear Action Names
Use descriptive, verb-based action names:

```ruby
# Good: Clear intent
actions :validate_order, :process_payment, :ship_order, :send_confirmation

# Avoid: Vague names
actions :do_stuff, :handle, :process
```

### 3. Proper Error Handling
Always handle errors gracefully:

```ruby
def process_payment
  return failure("No payment info") unless payment_present?
  
  begin
    result = payment_gateway.charge(@items[:amount])
    
    if result.success?
      success!
    else
      failure("Payment failed: #{result.error_message}")
    end
  rescue PaymentGatewayError => e
    failure("Gateway error: #{e.message}")
  end
  
  successful?
end
```

### 4. Idempotent Operations
Make operations safe to retry:

```ruby
def charge_payment
  # Check if already processed
  return success! if payment_already_charged?
  
  # Process only if not done
  result = charge_customer(@items[:amount])
  result.success? ? success! : failure(result.error)
  
  successful?
end

private

def payment_already_charged?
  PaymentRecord.exists?(order_id: @items[:order_id])
end
```

### 5. Meaningful Field Structures
Design clear, hierarchical data structures:

```ruby
# Good: Clear hierarchy
fields :order_id, :total_amount,
       { customer: [:name, :email, :phone] },
       { billing_address: [:street, :city, :state, :zip] },
       { items: [:product_id, :quantity, :unit_price] }

# Avoid: Flat structure
fields :order_id, :customer_name, :customer_email, :customer_phone,
       :billing_street, :billing_city, :billing_state, :billing_zip
```

## Advanced Patterns

### Message Inheritance
Create base classes for common functionality:

```ruby
class BaseProcessingMessage < BunnyFarm::Message
  def process
    start_processing
    perform_work
    complete_processing
  end
  
  private
  
  def start_processing
    @items[:started_at] = Time.current
  end
  
  def complete_processing
    @items[:completed_at] = Time.current
    success!
  end
  
  def perform_work
    raise NotImplementedError, "Subclass must implement perform_work"
  end
end

class OrderProcessingMessage < BaseProcessingMessage
  fields :order_id, :customer_id
  actions :process
  
  private
  
  def perform_work
    validate_order
    charge_payment
    update_inventory
  end
end
```

### Message Composition
Compose complex operations from simpler ones:

```ruby
class OrderWorkflowMessage < BunnyFarm::Message
  actions :start_workflow
  
  def start_workflow
    # Chain multiple message types
    validation_msg = OrderValidationMessage.new(@items)
    validation_msg.publish('validate')
    
    payment_msg = PaymentMessage.new(@items)
    payment_msg.publish('charge')
    
    shipping_msg = ShippingMessage.new(@items)
    shipping_msg.publish('create_label')
    
    success!
  end
end
```

## Next Steps

Now that you understand message-centric design:

- **[Smart Routing](smart-routing.md)** - How messages find their destination
- **[JSON Serialization](json-serialization.md)** - Data format and serialization
- **[Message Structure](../message-structure/overview.md)** - Deep dive into implementation