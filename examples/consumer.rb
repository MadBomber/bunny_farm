#!/usr/bin/env ruby
# Consumer example - processes messages from RabbitMQ

require 'bundler/setup'
require 'bunny_farm'
require_relative 'simple_message'

# Configure BunnyFarm
BunnyFarm.config do
  env 'development'
  app_id 'greeting_consumer'
  # Set routing key to match all GreetingMessage actions
  bunny Hashie::Mash.new(
    YAML.load(
      ERB.new(
        File.read(
          File.join(BunnyFarm::CONFIG.config_dir, BunnyFarm::CONFIG.bunny_file)
        )
      ).result, aliases: true
    )[BunnyFarm::CONFIG.env].merge(
      'routing_key' => 'GreetingMessage.*'
    )
  )
end

puts "BunnyFarm Consumer Example"
puts "=" * 40
puts "Waiting for messages from RabbitMQ..."
puts "Queue: #{BunnyFarm::CONFIG.bunny.queue_name}"
puts "Exchange: #{BunnyFarm::CONFIG.bunny.exchange_name}"
puts "Routing Key: #{BunnyFarm::CONFIG.bunny.routing_key}"
puts "=" * 40
puts "Press Ctrl+C to exit"
puts

# Start consuming messages (this will block)
begin
  BunnyFarm.manage(false)  # false = run in foreground (blocking)
rescue Interrupt
  puts "\n\nShutting down consumer..."
end