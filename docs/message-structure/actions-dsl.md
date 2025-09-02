# Actions DSL

The Actions DSL defines the operations that your message can perform. Each action becomes a routable method that can be called when the message is consumed.

## Basic Actions

```ruby
class OrderMessage < BunnyFarm::Message
  actions :validate, :process, :ship, :cancel
  
  def validate
    # Validation logic
    success!
  end
  
  def process
    # Processing logic
    success!
  end
  
  def ship
    # Shipping logic
    success!
  end
  
  def cancel
    # Cancellation logic
    success!
  end
end
```

## Action Method Implementation

Each action must be implemented as a method:

```ruby
class PaymentMessage < BunnyFarm::Message
  actions :authorize, :capture, :refund
  
  def authorize
    result = payment_gateway.authorize(@items[:amount], @items[:card_token])
    
    if result.success?
      @items[:authorization_id] = result.authorization_id
      success!
    else
      failure("Authorization failed: #{result.error_message}")
    end
    
    successful?
  end
  
  def capture
    return failure("No authorization ID") unless @items[:authorization_id]
    
    result = payment_gateway.capture(@items[:authorization_id])
    
    if result.success?
      @items[:transaction_id] = result.transaction_id
      success!
    else
      failure("Capture failed: #{result.error_message}")
    end
    
    successful?
  end
end
```

## Action Routing

Actions create routing keys automatically:

```ruby
# Publishing creates routing keys
message = PaymentMessage.new
message.publish('authorize')  # Routing key: PaymentMessage.authorize
message.publish('capture')    # Routing key: PaymentMessage.capture
message.publish('refund')     # Routing key: PaymentMessage.refund
```

## Action Patterns

### CRUD Operations
```ruby
class UserMessage < BunnyFarm::Message
  actions :create, :read, :update, :delete
end
```

### Workflow Actions
```ruby
class OrderWorkflow < BunnyFarm::Message
  actions :start, :validate, :process_payment, :fulfill, :ship, :complete
end
```

### State Machine Actions
```ruby
class DocumentMessage < BunnyFarm::Message
  actions :draft, :review, :approve, :publish, :archive
end
```

## Action Validation

```ruby
class ValidatedActions < BunnyFarm::Message
  actions :process
  
  def process
    # Validate before processing
    return unless validate_preconditions
    
    # Perform work
    do_processing
    
    # Validate after processing
    return unless validate_postconditions
    
    success!
  end
  
  private
  
  def validate_preconditions
    failure("Missing required data") unless required_data_present?
    successful?
  end
  
  def validate_postconditions
    failure("Processing incomplete") unless processing_complete?
    successful?
  end
end
```

## Best Practices

### 1. Use Descriptive Action Names
```ruby
# Good: Clear, descriptive names
actions :validate_order, :process_payment, :ship_order, :send_confirmation

# Avoid: Vague or generic names
actions :do_stuff, :handle, :process
```

### 2. Single Responsibility
```ruby
# Good: Each action has one purpose
actions :validate_customer, :validate_inventory, :validate_payment

# Avoid: Actions that do too much
actions :validate_everything
```

### 3. Logical Flow
```ruby
# Good: Actions follow logical order
actions :create_draft, :add_content, :review, :approve, :publish
```