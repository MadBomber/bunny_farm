#!/usr/bin/env ruby
# Task scheduler example - demonstrates scheduled/delayed message processing

require 'bundler/setup'
require 'bunny_farm'
require 'time'

# Message class for scheduled tasks
class ScheduledTask < BunnyFarm::Message
  fields :task_id, :task_type, :scheduled_for, :payload, :retry_count
  actions :execute, :retry, :report_failure
  
  def execute(*args)
    scheduled_time = Time.parse(@items[:scheduled_for])
    current_time = Time.now
    
    puts "\n⏰ Executing scheduled task ##{@items[:task_id]}"
    puts "   Type: #{@items[:task_type]}"
    puts "   Scheduled for: #{scheduled_time}"
    puts "   Current time: #{current_time}"
    
    # Check if we should execute now
    if current_time < scheduled_time
      delay = (scheduled_time - current_time).to_i
      puts "   ⏳ Too early! Delaying for #{delay} seconds..."
      
      # In a real system, you might requeue with a delay
      # For demo, we'll just sleep
      sleep [delay, 5].min  # Cap at 5 seconds for demo
    end
    
    # Execute the task based on type
    case @items[:task_type]
    when 'email_reminder'
      send_email_reminder
    when 'data_backup'
      perform_backup
    when 'report_generation'
      generate_report
    when 'cleanup'
      perform_cleanup
    else
      failure("Unknown task type: #{@items[:task_type]}")
      return
    end
    
    success!
  rescue => e
    puts "   ❌ Task failed: #{e.message}"
    
    # Increment retry count
    @items[:retry_count] = (@items[:retry_count] || 0) + 1
    
    if @items[:retry_count] < 3
      publish('retry')
    else
      publish('report_failure')
    end
    
    failure(e.message)
  end
  
  def retry(*args)
    puts "\n🔄 Retrying task ##{@items[:task_id]} (attempt #{@items[:retry_count]})"
    
    # Add exponential backoff
    sleep_time = 2 ** @items[:retry_count]
    puts "   Waiting #{sleep_time} seconds before retry..."
    sleep sleep_time
    
    # Re-execute
    publish('execute')
    success!
  end
  
  def report_failure(*args)
    puts "\n🚨 Task ##{@items[:task_id]} failed after #{@items[:retry_count]} attempts!"
    puts "   Sending failure notification..."
    
    # In a real system, this might send alerts to administrators
    # Log to error tracking service, send emails, etc.
    
    success!  # We successfully handled the failure
  end
  
  private
  
  def send_email_reminder
    puts "   📧 Sending email reminder..."
    recipient = @items[:payload]['recipient'] || 'user@example.com'
    subject = @items[:payload]['subject'] || 'Reminder'
    puts "      To: #{recipient}"
    puts "      Subject: #{subject}"
    
    # Simulate email sending
    sleep 0.5
    
    # Randomly fail sometimes for demo
    raise "SMTP connection failed" if rand > 0.8
    
    puts "   ✅ Email sent successfully"
  end
  
  def perform_backup
    puts "   💾 Performing data backup..."
    database = @items[:payload]['database'] || 'main_db'
    puts "      Database: #{database}"
    
    # Simulate backup
    sleep 1
    
    backup_file = "/backups/#{database}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.sql"
    puts "   ✅ Backup completed: #{backup_file}"
  end
  
  def generate_report
    puts "   📊 Generating report..."
    report_type = @items[:payload]['type'] || 'daily_sales'
    puts "      Type: #{report_type}"
    
    # Simulate report generation
    sleep 0.8
    
    puts "   ✅ Report generated and sent to stakeholders"
  end
  
  def perform_cleanup
    puts "   🧹 Performing cleanup tasks..."
    target = @items[:payload]['target'] || 'temp_files'
    puts "      Target: #{target}"
    
    # Simulate cleanup
    sleep 0.3
    
    puts "   ✅ Cleaned up #{rand(10..50)} old #{target}"
  end
end

# Main execution
if __FILE__ == $0
  require 'optparse'
  
  mode = nil
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on("-s", "--scheduler", "Run as task scheduler (producer)") { mode = :scheduler }
    opts.on("-w", "--worker", "Run as task worker (consumer)") { mode = :worker }
    opts.on("-h", "--help", "Show this help") do
      puts opts
      exit
    end
  end.parse!
  
  if mode.nil?
    puts "Please specify --scheduler or --worker mode"
    exit 1
  end
  
  # Configure BunnyFarm
  BunnyFarm.config do
    env 'development'
    app_id mode == :scheduler ? 'task_scheduler' : 'task_worker'
    
    if mode == :worker
      # Configure to receive all ScheduledTask actions
      bunny Hashie::Mash.new(
        YAML.load(
          ERB.new(
            File.read(
              File.join(BunnyFarm::CONFIG.config_dir, BunnyFarm::CONFIG.bunny_file)
            )
          ).result, aliases: true
        )[BunnyFarm::CONFIG.env].merge(
          'routing_key' => 'ScheduledTask.*'
        )
      )
    end
  end
  
  if mode == :scheduler
    puts "Task Scheduler"
    puts "=" * 40
    puts "Scheduling tasks for execution..."
    
    # Create various scheduled tasks
    tasks = [
      {
        task_id: "TASK-#{rand(1000..9999)}",
        task_type: 'email_reminder',
        scheduled_for: (Time.now + 2).to_s,  # 2 seconds from now
        payload: {
          'recipient' => 'alice@example.com',
          'subject' => 'Meeting in 15 minutes'
        },
        retry_count: 0
      },
      {
        task_id: "TASK-#{rand(1000..9999)}",
        task_type: 'data_backup',
        scheduled_for: Time.now.to_s,  # Execute immediately
        payload: {
          'database' => 'users_db'
        },
        retry_count: 0
      },
      {
        task_id: "TASK-#{rand(1000..9999)}",
        task_type: 'report_generation',
        scheduled_for: (Time.now + 5).to_s,  # 5 seconds from now
        payload: {
          'type' => 'weekly_analytics'
        },
        retry_count: 0
      },
      {
        task_id: "TASK-#{rand(1000..9999)}",
        task_type: 'cleanup',
        scheduled_for: (Time.now + 3).to_s,  # 3 seconds from now
        payload: {
          'target' => 'log_files'
        },
        retry_count: 0
      }
    ]
    
    tasks.each do |task_data|
      msg = ScheduledTask.new
      
      task_data.each do |key, value|
        msg[key] = value
      end
      
      if msg.publish('execute')
        puts "✅ Scheduled task #{task_data[:task_id]} (#{task_data[:task_type]})"
        puts "   Scheduled for: #{task_data[:scheduled_for]}"
      else
        puts "❌ Failed to schedule task: #{msg.errors.join(', ')}"
      end
      
      sleep 0.5
    end
    
    puts "\n📅 All tasks scheduled!"
    puts "Run with --worker in another terminal to process them."
    
  else  # worker mode
    puts "Task Worker"
    puts "=" * 40
    puts "Processing scheduled tasks..."
    puts "Press Ctrl+C to exit"
    
    begin
      BunnyFarm.manage(false)
    rescue Interrupt
      puts "\n\nShutting down task worker..."
    end
  end
  
  # Clean up
  if BunnyFarm::CONFIG.connection && BunnyFarm::CONFIG.connection.open?
    BunnyFarm::CONFIG.connection.close
  end
end