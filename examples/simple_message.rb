#!/usr/bin/env ruby
# Simple message class example

require 'bundler/setup'
require 'bunny_farm'

# Define a simple message class for processing greetings
class GreetingMessage < BunnyFarm::Message
  # Define the fields this message expects
  fields :name, :greeting_type, :timestamp
  
  # Define the actions this message can handle
  actions :say_hello, :say_goodbye
  
  def say_hello(*args)
    puts "👋 Hello, #{@items[:name]}!"
    puts "Received at: #{@items[:timestamp]}"
    
    # Simulate some processing
    sleep 0.5
    
    # Mark as successful
    success!
  end
  
  def say_goodbye(*args)
    puts "👋 Goodbye, #{@items[:name]}!"
    puts "Until next time at: #{@items[:timestamp]}"
    
    # Simulate some processing
    sleep 0.5
    
    # Mark as successful
    success!
  end
end

if __FILE__ == $0
  puts "Simple Message Class Example"
  puts "=" * 40
  puts "This file defines the GreetingMessage class."
  puts "Use producer.rb to send messages and consumer.rb to process them."
end