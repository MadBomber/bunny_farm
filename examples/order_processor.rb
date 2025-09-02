#!/usr/bin/env ruby
# Order processing example with multiple actions and error handling

require 'bundler/setup'
require 'bunny_farm'
require 'json'

# Example of a more complex message class for order processing
class OrderMessage < BunnyFarm::Message
  # Define fields including nested structures
  fields :order_id, :total_amount, :status,
         { customer: [:name, :email, :phone] },
         { items: [:product_id, :quantity, :price] },
         :created_at
  
  # Define multiple actions for different stages of order processing
  actions :validate, :process_payment, :ship, :cancel
  
  def validate(*args)
    puts "\n📋 Validating order ##{@items[:order_id]}"
    
    # Check required fields
    if @items[:customer][:email].nil? || @items[:customer][:email].empty?
      failure("Customer email is required")
      return
    end
    
    if @items[:total_amount].to_f <= 0
      failure("Invalid order amount: #{@items[:total_amount]}")
      return
    end
    
    # Simulate validation
    sleep 0.5
    
    puts "   ✅ Order validation passed"
    puts "   Customer: #{@items[:customer][:name]} (#{@items[:customer][:email]})"
    puts "   Amount: $#{'%.2f' % @items[:total_amount]}"
    
    # Update status
    @items[:status] = 'validated'
    
    # Publish next step
    publish('process_payment')
    
    success!
  end
  
  def process_payment(*args)
    puts "\n💳 Processing payment for order ##{@items[:order_id]}"
    
    # Simulate payment processing
    sleep 1
    
    # Randomly simulate payment success/failure for demo
    if rand > 0.2  # 80% success rate
      puts "   ✅ Payment successful: $#{'%.2f' % @items[:total_amount]}"
      @items[:status] = 'paid'
      
      # Publish next step
      publish('ship')
      success!
    else
      puts "   ❌ Payment failed - insufficient funds"
      @items[:status] = 'payment_failed'
      
      # Publish cancellation
      publish('cancel')
      failure("Payment processing failed")
    end
  end
  
  def ship(*args)
    puts "\n📦 Shipping order ##{@items[:order_id]}"
    puts "   To: #{@items[:customer][:name]}"
    puts "   Email: #{@items[:customer][:email]}"
    
    # Simulate shipping process
    sleep 0.5
    
    tracking_number = "TRK#{rand(100000..999999)}"
    puts "   🚚 Tracking number: #{tracking_number}"
    
    @items[:status] = 'shipped'
    @items[:tracking_number] = tracking_number
    
    # Send notification email (simulated)
    send_notification('shipped')
    
    success!
  end
  
  def cancel(*args)
    puts "\n❌ Cancelling order ##{@items[:order_id]}"
    puts "   Reason: #{@errors.last if @errors}"
    
    @items[:status] = 'cancelled'
    
    # Send cancellation email (simulated)
    send_notification('cancelled')
    
    success!  # Even cancellation is handled successfully
  end
  
  private
  
  def send_notification(type)
    puts "   📧 Sending #{type} notification to #{@items[:customer][:email]}"
  end
end

# Producer/Consumer combo for demonstration
if __FILE__ == $0
  require 'optparse'
  
  mode = nil
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on("-p", "--producer", "Run as producer") { mode = :producer }
    opts.on("-c", "--consumer", "Run as consumer") { mode = :consumer }
    opts.on("-h", "--help", "Show this help") do
      puts opts
      exit
    end
  end.parse!
  
  if mode.nil?
    puts "Please specify --producer or --consumer mode"
    exit 1
  end
  
  # Configure BunnyFarm
  BunnyFarm.config do
    env 'development'
    app_id mode == :producer ? 'order_producer' : 'order_consumer'
    
    if mode == :consumer
      # Configure to receive all OrderMessage actions
      bunny Hashie::Mash.new(
        YAML.load(
          ERB.new(
            File.read(
              File.join(BunnyFarm::CONFIG.config_dir, BunnyFarm::CONFIG.bunny_file)
            )
          ).result, aliases: true
        )[BunnyFarm::CONFIG.env].merge(
          'routing_key' => 'OrderMessage.*'
        )
      )
    end
  end
  
  if mode == :producer
    puts "Order Processing Producer"
    puts "=" * 40
    
    # Create sample orders
    orders = [
      {
        order_id: "ORD-#{rand(1000..9999)}",
        total_amount: 99.99,
        status: 'new',
        customer: {
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1-555-0123'
        },
        items: [
          { product_id: 'PROD-001', quantity: 2, price: 49.99 }
        ],
        created_at: Time.now.to_s
      },
      {
        order_id: "ORD-#{rand(1000..9999)}",
        total_amount: 149.50,
        status: 'new',
        customer: {
          name: 'Jane Smith',
          email: 'jane@example.com',
          phone: '+1-555-0124'
        },
        items: [
          { product_id: 'PROD-002', quantity: 1, price: 149.50 }
        ],
        created_at: Time.now.to_s
      },
      {
        order_id: "ORD-#{rand(1000..9999)}",
        total_amount: 0,  # This will fail validation
        status: 'new',
        customer: {
          name: 'Bad Order',
          email: '',  # This will also fail
          phone: ''
        },
        items: [],
        created_at: Time.now.to_s
      }
    ]
    
    orders.each do |order_data|
      msg = OrderMessage.new
      
      # Populate message fields
      order_data.each do |key, value|
        msg[key] = value
      end
      
      # Start the order processing workflow
      if msg.publish('validate')
        puts "✅ Sent order #{order_data[:order_id]} for validation"
      else
        puts "❌ Failed to send order: #{msg.errors.join(', ')}"
      end
      
      sleep 1
    end
    
    puts "\n📬 All orders sent for processing!"
    
  else  # consumer mode
    puts "Order Processing Consumer"
    puts "=" * 40
    puts "Waiting for order messages..."
    puts "Press Ctrl+C to exit"
    
    begin
      BunnyFarm.manage(false)
    rescue Interrupt
      puts "\n\nShutting down order processor..."
    end
  end
  
  # Clean up
  if BunnyFarm::CONFIG.connection && BunnyFarm::CONFIG.connection.open?
    BunnyFarm::CONFIG.connection.close
  end
end