#!/usr/bin/env ruby
# Producer example - sends messages to RabbitMQ

require 'bundler/setup'
require 'bunny_farm'
require_relative 'simple_message'

# Configure BunnyFarm
BunnyFarm.config do
  env 'development'
  app_id 'greeting_producer'
end

puts "BunnyFarm Producer Example"
puts "=" * 40
puts "Sending messages to RabbitMQ..."
puts "Queue: #{BunnyFarm::CONFIG.bunny.queue_name}"
puts "Exchange: #{BunnyFarm::CONFIG.bunny.exchange_name}"
puts "=" * 40

# Create and send hello messages
3.times do |i|
  msg = GreetingMessage.new
  msg[:name] = "User #{i + 1}"
  msg[:greeting_type] = 'hello'
  msg[:timestamp] = Time.now.to_s
  
  if msg.publish('say_hello')
    puts "✅ Sent hello message for User #{i + 1}"
  else
    puts "❌ Failed to send hello message: #{msg.errors.join(', ')}"
  end
  
  sleep 0.5
end

# Create and send goodbye messages
2.times do |i|
  msg = GreetingMessage.new
  msg[:name] = "Guest #{i + 1}"
  msg[:greeting_type] = 'goodbye'
  msg[:timestamp] = Time.now.to_s
  
  if msg.publish('say_goodbye')
    puts "✅ Sent goodbye message for Guest #{i + 1}"
  else
    puts "❌ Failed to send goodbye message: #{msg.errors.join(', ')}"
  end
  
  sleep 0.5
end

puts "\n📬 All messages sent!"
puts "Run consumer.rb in another terminal to process them."

# Clean up
if BunnyFarm::CONFIG.connection && BunnyFarm::CONFIG.connection.open?
  BunnyFarm::CONFIG.connection.close
  puts "Connection closed."
end