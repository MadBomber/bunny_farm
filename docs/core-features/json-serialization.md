# JSON Serialization

BunnyFarm uses JSON as its message serialization format, providing human-readable, language-agnostic message passing that's easy to debug and integrate with other systems.

## Why JSON?

### Human Readable
JSON messages are easy to read and debug:

```json
{
  "order_id": 12345,
  "customer": {
    "name": "John Doe",
    "email": "john@example.com"
  },
  "items": [
    {
      "product_id": 1,
      "quantity": 2,
      "price": 29.99
    }
  ],
  "total": 59.98,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Language Agnostic
Other systems can easily produce and consume messages:

```python
# Python producer
import json
import pika

message = {
    "order_id": 12345,
    "customer": {"name": "John", "email": "john@example.com"},
    "total": 59.98
}

channel.basic_publish(
    exchange='bunny_farm_exchange',
    routing_key='OrderMessage.process',
    body=json.dumps(message)
)
```

### Tooling Support
Rich ecosystem of JSON tools for debugging and monitoring.

## Serialization Process

### Publishing Flow

```ruby
class OrderMessage < BunnyFarm::Message
  fields :order_id, :customer, :items
end

# 1. Create message
message = OrderMessage.new
message[:order_id] = 12345
message[:customer] = { name: "John", email: "john@example.com" }

# 2. Publish - automatic serialization
message.publish('process')
```

**Internal process:**
1. Message data collected from `@items` hash
2. Data serialized to JSON string
3. JSON sent to RabbitMQ as message body
4. Routing key: `OrderMessage.process`

### Consumption Flow

```ruby
# Consumer receives JSON message body and routing key
# BunnyFarm automatically:
# 1. Parses routing key → OrderMessage.process
# 2. Deserializes JSON to Ruby hash
# 3. Creates OrderMessage instance
# 4. Populates @items with deserialized data
# 5. Calls 'process' method

class OrderMessage < BunnyFarm::Message
  def process
    puts @items[:order_id]        # 12345
    puts @items[:customer][:name] # "John"
    success!
  end
end
```

## Data Types and Serialization

### Supported Data Types

JSON supports these Ruby types natively:

```ruby
message = OrderMessage.new

# String
message[:customer_name] = "John Doe"

# Number (Integer/Float)
message[:order_id] = 12345
message[:total] = 59.99

# Boolean
message[:is_priority] = true
message[:requires_signature] = false

# Null
message[:notes] = nil

# Array
message[:items] = [
  { product_id: 1, quantity: 2 },
  { product_id: 2, quantity: 1 }
]

# Hash/Object
message[:customer] = {
  name: "John Doe",
  email: "john@example.com",
  address: {
    street: "123 Main St",
    city: "Boston",
    state: "MA"
  }
}
```

### Serialized JSON Output

```json
{
  "customer_name": "John Doe",
  "order_id": 12345,
  "total": 59.99,
  "is_priority": true,
  "requires_signature": false,
  "notes": null,
  "items": [
    {"product_id": 1, "quantity": 2},
    {"product_id": 2, "quantity": 1}
  ],
  "customer": {
    "name": "John Doe", 
    "email": "john@example.com",
    "address": {
      "street": "123 Main St",
      "city": "Boston",
      "state": "MA"
    }
  }
}
```

## Complex Data Handling

### Date and Time

Dates should be serialized as ISO 8601 strings:

```ruby
class OrderMessage < BunnyFarm::Message
  def set_timestamps
    @items[:created_at] = Time.current.iso8601
    @items[:processed_at] = DateTime.current.iso8601
  end
  
  def get_created_time
    Time.parse(@items[:created_at])
  end
end

# JSON output
{
  "created_at": "2024-01-15T10:30:00Z",
  "processed_at": "2024-01-15T10:30:00+00:00"
}
```

### Binary Data

Base64 encode binary data:

```ruby
class DocumentMessage < BunnyFarm::Message
  def set_file_content(file_path)
    content = File.binread(file_path)
    @items[:file_content] = Base64.encode64(content)
    @items[:filename] = File.basename(file_path)
  end
  
  def get_file_content
    Base64.decode64(@items[:file_content])
  end
end
```

### Custom Objects

Convert complex objects to simple data structures:

```ruby
class Customer
  attr_accessor :id, :name, :email, :created_at
  
  def to_hash
    {
      id: @id,
      name: @name,
      email: @email,
      created_at: @created_at.iso8601
    }
  end
  
  def self.from_hash(data)
    customer = new
    customer.id = data[:id]
    customer.name = data[:name]
    customer.email = data[:email]
    customer.created_at = Time.parse(data[:created_at])
    customer
  end
end

class OrderMessage < BunnyFarm::Message
  def set_customer(customer)
    @items[:customer] = customer.to_hash
  end
  
  def get_customer
    Customer.from_hash(@items[:customer])
  end
end
```

## Performance Considerations

### Message Size

JSON can become large with complex data:

```ruby
# Monitor message sizes
class OrderMessage < BunnyFarm::Message
  def publish(action)
    json_size = to_json.bytesize
    logger.warn "Large message: #{json_size} bytes" if json_size > 10.kilobytes
    
    super(action)
  end
end
```

### Compression

For large messages, consider compression:

```ruby
require 'zlib'

class LargeDataMessage < BunnyFarm::Message
  def set_compressed_data(data)
    json_data = data.to_json
    compressed = Zlib::Deflate.deflate(json_data)
    @items[:compressed_data] = Base64.encode64(compressed)
    @items[:compression] = 'zlib'
  end
  
  def get_decompressed_data
    return @items[:data] unless @items[:compression]
    
    compressed = Base64.decode64(@items[:compressed_data])
    json_data = Zlib::Inflate.inflate(compressed)
    JSON.parse(json_data)
  end
end
```

### Parsing Performance

JSON parsing can be optimized:

```ruby
# Use Oj gem for faster JSON parsing
require 'oj'

class FastMessage < BunnyFarm::Message
  def to_json
    Oj.dump(@items, mode: :compat)
  end
  
  def self.from_json(json_string)
    data = Oj.load(json_string, mode: :compat)
    message = new
    message.instance_variable_set(:@items, data)
    message
  end
end
```

## Debugging JSON Messages

### Pretty Printing

Format JSON for easier reading:

```ruby
require 'json'

class OrderMessage < BunnyFarm::Message
  def pretty_print
    JSON.pretty_generate(@items)
  end
end

puts message.pretty_print
```

Output:
```json
{
  "order_id": 12345,
  "customer": {
    "name": "John Doe",
    "email": "john@example.com"
  },
  "items": [
    {
      "product_id": 1,
      "quantity": 2
    }
  ]
}
```

### JSON Validation

Validate message structure:

```ruby
require 'json-schema'

class ValidatedMessage < BunnyFarm::Message
  SCHEMA = {
    type: 'object',
    required: ['order_id', 'customer'],
    properties: {
      order_id: { type: 'integer' },
      customer: {
        type: 'object',
        required: ['name', 'email'],
        properties: {
          name: { type: 'string' },
          email: { type: 'string', format: 'email' }
        }
      }
    }
  }.freeze
  
  def validate_schema
    errors = JSON::Validator.fully_validate(SCHEMA, @items)
    failure("Schema validation failed: #{errors.join(', ')}") unless errors.empty?
  end
end
```

### Message Inspection

Inspect messages in RabbitMQ management UI or with tools:

```bash
# View message in RabbitMQ management interface
# Messages tab → Get Messages → View JSON payload

# Use rabbitmqadmin to inspect messages
rabbitmqadmin get queue=order_queue requeue=true

# Use jq to format JSON in command line
echo '{"order_id":12345,"customer":{"name":"John"}}' | jq '.'
```

## Integration Patterns

### Multi-Language Consumers

Other languages can consume BunnyFarm messages:

**Python Consumer:**
```python
import json
import pika

def process_order(channel, method, properties, body):
    # Parse BunnyFarm JSON message
    message_data = json.loads(body)
    order_id = message_data['order_id']
    customer = message_data['customer']
    
    # Process order
    print(f"Processing order {order_id} for {customer['name']}")
    
    # Acknowledge message
    channel.basic_ack(delivery_tag=method.delivery_tag)

# Set up consumer
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()
channel.basic_consume(queue='order_queue', on_message_callback=process_order)
channel.start_consuming()
```

**Node.js Consumer:**
```javascript
const amqp = require('amqplib');

async function processOrders() {
  const connection = await amqp.connect('amqp://localhost');
  const channel = await connection.createChannel();
  
  channel.consume('order_queue', (message) => {
    // Parse BunnyFarm JSON message
    const messageData = JSON.parse(message.content.toString());
    const orderId = messageData.order_id;
    const customer = messageData.customer;
    
    console.log(`Processing order ${orderId} for ${customer.name}`);
    
    // Acknowledge message
    channel.ack(message);
  });
}
```

### API Gateway Integration

Expose message creation via REST API:

```ruby
class OrdersController < ApplicationController
  def create
    # Create message from API payload
    order_message = OrderMessage.new
    order_message[:order_id] = params[:order_id]
    order_message[:customer] = params[:customer]
    order_message[:items] = params[:items]
    
    # Publish for processing
    if order_message.publish('process')
      render json: { status: 'accepted', order_id: params[:order_id] }
    else
      render json: { error: 'Failed to process order' }, status: 500
    end
  end
end
```

## Best Practices

### 1. Keep Messages Focused

```ruby
# Good: Focused message structure
class OrderMessage < BunnyFarm::Message
  fields :order_id, :customer_id, :items, :total, :shipping_address
end

# Avoid: Kitchen sink approach
class EverythingMessage < BunnyFarm::Message
  fields :order_data, :customer_data, :inventory_data, :shipping_data,
         :payment_data, :analytics_data, :audit_data, :metadata
end
```

### 2. Use Consistent Naming

```ruby
# Good: Consistent snake_case
{
  "order_id": 12345,
  "customer_email": "john@example.com",
  "created_at": "2024-01-15T10:30:00Z"
}

# Avoid: Mixed naming conventions
{
  "orderId": 12345,           # camelCase
  "customer_email": "john@example.com",  # snake_case  
  "CreatedAt": "2024-01-15T10:30:00Z"    # PascalCase
}
```

### 3. Version Your Message Structure

```ruby
class OrderMessage < BunnyFarm::Message
  def initialize
    super
    @items[:_version] = '1.0'
  end
  
  def process
    case @items[:_version]
    when '1.0'
      process_v1
    when '2.0'
      process_v2
    else
      failure("Unsupported message version: #{@items[:_version]}")
    end
  end
end
```

### 4. Handle Missing Fields Gracefully

```ruby
def process
  order_id = @items[:order_id]
  return failure("Order ID required") unless order_id
  
  customer_email = @items.dig(:customer, :email)
  return failure("Customer email required") unless customer_email
  
  # Process with validated data
  success!
end
```

## Next Steps

With JSON serialization mastered:

- **[Configure message formats](../configuration/overview.md)** for your environment
- **[Design message structures](../message-structure/overview.md)** for optimal serialization
- **[Handle errors](error-handling.md)** in serialization and deserialization
- **[Integrate with other systems](../architecture/integration.md)** using JSON