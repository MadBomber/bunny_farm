# Installation

BunnyFarm is distributed as a Ruby gem and can be installed using bundler or gem directly.

## Requirements

Before installing BunnyFarm, ensure you have:

- **Ruby 2.5 or higher** - BunnyFarm supports modern Ruby versions
- **RabbitMQ server** - Either local installation or cloud service
- **Bundler** - For dependency management

## Installing BunnyFarm

### Using Bundler (Recommended)

Add this line to your application's Gemfile:

```ruby
gem 'bunny_farm'
```

Then execute:

```bash
bundle install
```

### Using Gem Directly

Install it yourself as:

```bash
gem install bunny_farm
```

## Setting up RabbitMQ

### Local Installation

#### macOS (using Homebrew)

```bash
# Install RabbitMQ
brew install rabbitmq

# Start RabbitMQ server
brew services start rabbitmq

# Enable management plugin (optional but recommended)
rabbitmq-plugins enable rabbitmq_management
```

#### Ubuntu/Debian

```bash
# Install RabbitMQ
sudo apt-get update
sudo apt-get install rabbitmq-server

# Start RabbitMQ server
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server

# Enable management plugin
sudo rabbitmq-plugins enable rabbitmq_management
```

#### Docker

```bash
# Run RabbitMQ with management plugin
docker run -d \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  rabbitmq:3-management
```

### Cloud Services

BunnyFarm works with cloud RabbitMQ services:

- **CloudAMQP** - Managed RabbitMQ service
- **Amazon MQ** - AWS managed message broker
- **Google Cloud Pub/Sub** - With AMQP support
- **Azure Service Bus** - With AMQP 1.0 support

## Verification

Verify your installation by checking if BunnyFarm loads correctly:

```ruby
require 'bunny_farm'
puts BunnyFarm::VERSION
```

You should see the version number output without any errors.

## Environment Setup

Set up your environment variables for development:

```bash
export AMQP_HOST=localhost
export AMQP_VHOST=/
export AMQP_PORT=5672
export AMQP_USER=guest
export AMQP_PASS=guest
export AMQP_EXCHANGE=bunny_farm_exchange
export AMQP_QUEUE=bunny_farm_queue
export AMQP_ROUTING_KEY='#'
export AMQP_APP_NAME=my_bunny_farm_app
```

## Next Steps

With BunnyFarm installed and RabbitMQ running, you're ready to:

1. **[Quick Start Guide](quick-start.md)** - Get your first message processing in 5 minutes
2. **[Basic Concepts](basic-concepts.md)** - Understand BunnyFarm's core concepts
3. **[Configuration](../configuration/overview.md)** - Learn about configuration options