# Configuration

BunnyFarm provides flexible configuration options that adapt to different environments and deployment scenarios. This page covers configuration as a core feature that enables the framework's adaptability.

## Configuration Philosophy

BunnyFarm follows the principle of **sensible defaults with easy customization**:

- **Zero configuration** - Works out of the box for development
- **Environment aware** - Adapts to different deployment contexts
- **Override hierarchy** - Multiple configuration layers with clear precedence
- **Runtime flexibility** - Can be configured programmatically or declaratively

## Configuration as a Feature

### Environment Adaptation

BunnyFarm automatically adapts to different environments:

```ruby
# Development - uses localhost defaults
BunnyFarm.config { env 'development' }

# Production - uses environment variables or config files
BunnyFarm.config do
  env 'production'
  bunny_file 'config/production.yml'
end

# Testing - isolated configuration
BunnyFarm.config do
  env 'test'
  exchange_name 'test_exchange'
  queue_name 'test_queue'
end
```

### Dynamic Configuration

Configuration can adapt to runtime conditions:

```ruby
BunnyFarm.config do
  # Dynamic host selection
  host case ENV['REGION']
       when 'us-east' then 'amqp-us-east.example.com'
       when 'eu-west' then 'amqp-eu-west.example.com'
       else 'localhost'
       end
  
  # Scale queue count based on load
  queue_name "orders_#{ENV['INSTANCE_ID'] || 'default'}"
  
  # Conditional features
  if ENV['ENABLE_MONITORING'] == 'true'
    monitoring_enabled true
    metrics_endpoint 'http://prometheus:9090'
  end
end
```

## Configuration Methods

### 1. Environment Variables

The most common production configuration method:

```bash
# Connection settings
export AMQP_HOST=amqp.example.com
export AMQP_PORT=5672
export AMQP_USER=app_user
export AMQP_PASS=secret_password
export AMQP_VHOST=production

# Application settings
export AMQP_EXCHANGE=production_exchange
export AMQP_QUEUE=production_queue
export AMQP_ROUTING_KEY='#'
export AMQP_APP_NAME=order_processor
```

**Usage:**
```ruby
# Automatically uses environment variables
BunnyFarm.config
```

### 2. YAML Configuration Files

Structured configuration with ERB templating:

**config/bunny.yml.erb:**
```yaml
defaults: &defaults
  host: <%= ENV['AMQP_HOST'] || 'localhost' %>
  port: <%= ENV['AMQP_PORT'] || 5672 %>
  user: <%= ENV['AMQP_USER'] || 'guest' %>
  pass: <%= ENV['AMQP_PASS'] || 'guest' %>
  vhost: <%= ENV['AMQP_VHOST'] || '/' %>

development:
  <<: *defaults
  exchange_name: dev_exchange
  queue_name: dev_queue

staging:
  <<: *defaults
  host: staging-amqp.example.com
  exchange_name: staging_exchange
  
production:
  <<: *defaults
  host: <%= ENV.fetch('PRODUCTION_AMQP_HOST') %>
  exchange_name: production_exchange
  connection_pool_size: 10
```

**Usage:**
```ruby
BunnyFarm.config do
  env Rails.env
  bunny_file 'config/bunny.yml.erb'
end
```

### 3. Programmatic Configuration

Ruby code-based configuration:

```ruby
BunnyFarm.config do
  # Basic settings
  app_id 'order_processor'
  env Rails.env
  
  # Connection settings
  host 'amqp.example.com'
  port 5672
  vhost '/orders'
  
  # Queue configuration
  exchange_name 'order_exchange'
  queue_name 'order_processing'
  routing_key 'OrderMessage.*'
  
  # Advanced options
  connection_pool_size 5
  heartbeat_interval 30
  
  # Message options
  message_options do
    persistent true
    mandatory false
  end
  
  # Queue options
  queue_options do
    durable true
    auto_delete false
    arguments({
      'x-message-ttl' => 300_000,  # 5 minutes
      'x-max-length' => 10_000
    })
  end
end
```

## Configuration Patterns

### Multi-Environment Setup

**Rails Application:**
```ruby
# config/environments/development.rb
BunnyFarm.config do
  env 'development'
  log_level :debug
end

# config/environments/staging.rb
BunnyFarm.config do
  env 'staging'
  bunny_file Rails.root.join('config', 'rabbitmq.yml')
  log_level :info
end

# config/environments/production.rb
BunnyFarm.config do
  env 'production'
  bunny_file Rails.root.join('config', 'rabbitmq.yml')
  log_level :warn
  
  # Production-specific settings
  connection_pool_size 10
  heartbeat_interval 60
  connection_timeout 30
end
```

### Docker Configuration

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  app:
    build: .
    environment:
      AMQP_HOST: rabbitmq
      AMQP_USER: app
      AMQP_PASS: ${RABBITMQ_PASSWORD}
      AMQP_EXCHANGE: ${APP_EXCHANGE:-app_exchange}
      AMQP_QUEUE: ${APP_QUEUE:-app_queue}
      RAILS_ENV: production
    depends_on:
      - rabbitmq
      
  rabbitmq:
    image: rabbitmq:3-management
    environment:
      RABBITMQ_DEFAULT_USER: app
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}
```

### Kubernetes Configuration

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: bunny-farm-config
data:
  AMQP_HOST: "rabbitmq-service"
  AMQP_EXCHANGE: "production_exchange"
  AMQP_QUEUE: "production_queue"
  AMQP_APP_NAME: "order-processor"
```

**Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bunny-farm-secret
type: Opaque
data:
  AMQP_USER: YXBwX3VzZXI=  # base64 encoded
  AMQP_PASS: c2VjcmV0X3Bhc3M=  # base64 encoded
```

**Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-processor
spec:
  template:
    spec:
      containers:
      - name: app
        image: order-processor:latest
        envFrom:
        - configMapRef:
            name: bunny-farm-config
        - secretRef:
            name: bunny-farm-secret
```

## Advanced Configuration Features

### Configuration Validation

```ruby
BunnyFarm.config do
  # Validate required settings
  required_env_vars = %w[AMQP_HOST AMQP_USER AMQP_PASS]
  missing = required_env_vars.select { |var| ENV[var].nil? }
  
  raise "Missing required environment variables: #{missing.join(', ')}" if missing.any?
  
  # Set configuration
  host ENV['AMQP_HOST']
  user ENV['AMQP_USER']
  pass ENV['AMQP_PASS']
end
```

### Conditional Configuration

```ruby
BunnyFarm.config do
  # Base configuration
  app_id 'message_processor'
  
  # Environment-specific
  case ENV['RAILS_ENV']
  when 'development'
    log_level :debug
    queue_name 'dev_queue'
  when 'test'
    log_level :fatal
    queue_name "test_queue_#{ENV['TEST_ENV_NUMBER']}"
  when 'production'
    log_level :info
    connection_pool_size 20
    queue_name 'prod_queue'
    
    # Enable monitoring in production
    monitoring_enabled true
    health_check_port 8080
  end
  
  # Feature flags
  if ENV['ENABLE_DEAD_LETTERS'] == 'true'
    dead_letter_exchange 'failed_messages'
    dead_letter_routing_key 'failed.#'
  end
end
```

### Runtime Configuration Updates

```ruby
class ConfigurableWorker
  def initialize
    @config_check_interval = 60  # Check every minute
    @last_config_check = Time.current
    setup_configuration
  end
  
  def process_messages
    loop do
      check_configuration_updates if should_check_config?
      
      BunnyFarm.manage_single_message
    end
  end
  
  private
  
  def should_check_config?
    Time.current - @last_config_check > @config_check_interval
  end
  
  def check_configuration_updates
    new_config = load_config_from_source
    
    if config_changed?(new_config)
      logger.info "Configuration updated, reloading..."
      update_configuration(new_config)
    end
    
    @last_config_check = Time.current
  end
  
  def config_changed?(new_config)
    @current_config_hash != new_config.hash
  end
  
  def update_configuration(new_config)
    BunnyFarm.reconfigure(new_config)
    @current_config_hash = new_config.hash
  end
end
```

## Configuration Security

### Secret Management

Never store secrets in code or version control:

```ruby
# Good: Use environment variables or secret management
BunnyFarm.config do
  user ENV['AMQP_USER']
  pass ENV['AMQP_PASS']  # From Kubernetes secret, HashiCorp Vault, etc.
end

# Avoid: Hardcoded secrets
BunnyFarm.config do
  user 'admin'
  pass 'secret123'  # Don't do this!
end
```

### Encrypted Configuration

For sensitive configuration files:

```ruby
require 'openssl'

class EncryptedConfig
  def self.load(file_path, key)
    encrypted_data = File.read(file_path)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.decrypt
    cipher.key = key
    
    decrypted_data = cipher.update(encrypted_data) + cipher.final
    YAML.safe_load(decrypted_data)
  end
end

# Usage
config_key = ENV['CONFIG_ENCRYPTION_KEY']
config = EncryptedConfig.load('config/encrypted_bunny.yml', config_key)

BunnyFarm.config do
  host config['host']
  user config['user']
  pass config['pass']
end
```

## Monitoring Configuration

### Health Checks

```ruby
BunnyFarm.config do
  # Enable health check endpoint
  health_check_enabled true
  health_check_port 8080
  health_check_path '/health'
end

# Health check responds with:
# GET /health
# {
#   "status": "healthy",
#   "rabbitmq_connection": "ok",
#   "queue_depth": 42,
#   "last_message_processed": "2024-01-15T10:30:00Z"
# }
```

### Metrics and Logging

```ruby
BunnyFarm.config do
  # Detailed logging
  log_level ENV['LOG_LEVEL']&.downcase&.to_sym || :info
  log_format :json  # For structured logging
  
  # Metrics
  metrics_enabled true
  metrics_port 9090
  metrics_path '/metrics'
  
  # Custom metric tags
  metric_tags({
    environment: ENV['RAILS_ENV'],
    region: ENV['AWS_REGION'],
    instance: ENV['HOSTNAME']
  })
end
```

## Best Practices

### 1. Layer Configuration Appropriately

```ruby
# Layer 1: Sensible defaults
BunnyFarm.config do
  host 'localhost'
  port 5672
  heartbeat_interval 30
end

# Layer 2: Environment-specific overrides
BunnyFarm.config do
  bunny_file "config/#{Rails.env}.yml"
end

# Layer 3: Runtime overrides
BunnyFarm.config do
  host ENV['AMQP_HOST'] if ENV['AMQP_HOST']
  log_level ENV['LOG_LEVEL'].to_sym if ENV['LOG_LEVEL']
end
```

### 2. Validate Critical Configuration

```ruby
BunnyFarm.config do
  host ENV.fetch('AMQP_HOST')  # Will raise if missing
  
  port_value = ENV['AMQP_PORT']&.to_i || 5672
  raise "Invalid port: #{port_value}" unless (1..65535).include?(port_value)
  port port_value
end
```

### 3. Document Configuration Options

```ruby
# config/bunny_farm.rb
BunnyFarm.config do
  # Connection settings - required in production
  host ENV['AMQP_HOST']        # RabbitMQ server hostname
  port ENV['AMQP_PORT']&.to_i  # RabbitMQ server port (default: 5672)
  vhost ENV['AMQP_VHOST']      # Virtual host (default: '/')
  
  # Authentication - use secrets in production
  user ENV['AMQP_USER']        # Username (default: 'guest')
  pass ENV['AMQP_PASS']        # Password (default: 'guest')
  
  # Message routing
  exchange_name ENV['AMQP_EXCHANGE'] || 'app_exchange'
  queue_name ENV['AMQP_QUEUE'] || 'app_queue'
  routing_key ENV['AMQP_ROUTING_KEY'] || '#'
end
```

## Next Steps

Configuration mastery enables:

- **[Environment-specific deployment](../architecture/overview.md)**
- **[Performance tuning](../architecture/scaling.md)** through configuration
- **[Security hardening](../development/contributing.md)** with proper secret management
- **[Monitoring and observability](error-handling.md)** through configuration