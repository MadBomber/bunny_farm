require 'bunny'
require 'erb'
require 'hashie'
require 'yaml'

require_relative 'generic_consumer'

module BunnyFarm

  CONFIG     = Hashie::Mash.new

  class << self

    def config(config_file=nil, &block)

      unless config_file.nil?
        config_dir  File.dirname(config_file)
        bunny_file  File.basename(config_file)
      end

      if block_given?
        class_eval(&block)
      end

      default :env, 'development'

      default :config_dir, File.dirname(__FILE__) + "/../../config/"

      default :bunny_file, 'bunny.yml.erb'

      default :bunny, Hashie::Mash.new(
                        YAML.load(
                          ERB.new(
                            File.read(
                              File.join(  CONFIG.config_dir,
                                          CONFIG.bunny_file))).result))[CONFIG.env]

      default :app_id, CONFIG.bunny.app_name

      default :connection, Bunny.new(CONFIG.bunny).tap(&:start)

      default :channel, CONFIG.connection.create_channel

      default :exchange, CONFIG.channel.topic(
                                  CONFIG.bunny.exchange_name,
                                  :durable => true,
                                  :auto_delete => false)

      default :queue, CONFIG.channel.queue(
                                      CONFIG.bunny.queue_name,
                                      durable: true,
                                      auto_delete: false,
                                      arguments: {"x-max-length" => 1000}
                                  ).bind(CONFIG.exchange,
                                      :routing_key => CONFIG.bunny.routing_key)

      default :control_c, false # used to signal that user hit the panic button

      default :consumer_tag, 'generic_consumer'

      default :no_ack,    false # false means that an acknowledgement is required
      default :exclusive, false

      # Usage: see BunnyFarm#manage
      default :run, GenericConsumer.new(
        CONFIG.channel,
        CONFIG.queue,
        CONFIG.consumer_tag,
        CONFIG.no_ack,
        CONFIG.exclusive
      )

      default :block, true  # set to false for background processing

    end # def self.config

    def default(key, value)
      set(key, value) if CONFIG[key].nil?
    end

    def set(key, value)
      STDERR.puts "Setting #{key} ..." if $debug
      CONFIG[key] = value
    end

    def method_missing(method_sym, *args, &block)
      STDERR.puts "METHOD-MISSING: #{method_sym}(#{args.join(', ')})" if $debug
      set(method_sym, args.first)
    end

    # Usage:
    #   BunnyFarm.manage(true)  -- manages queue in background
    #   BunnyFarm.manage(false) -- manages queue in foreground (eg. blocks; will not return)
    #   BunnyFarm.manage -- behavior controlled by BunnyFarm::CONFIG.block
    def manage(background=nil)

      if background.nil?
        background = CONFIG.block
      else
        background = !background # Counter-intutive based on POV of block
      end

      CONFIG.run.on_delivery do |info, metadata, payload|
        Thread.new do
          klass   = Kernel.const_get info.routing_key.split('.').first
          status  = klass.new(payload, info, metadata)
        end
      end # BunnyFarm.run.on_delivery do

      CONFIG.queue.subscribe_with( CONFIG.run, block: background )

    end # def self.manage
  end # class << self
end # module BunnyFarm


trap("INT") do
  BunnyFarm::CONFIG.control_c = true
end

# Need to clean up the smart pills -- rabbit joke
at_exit do

  if BunnyFarm::CONFIG.control_c
    STDERR.puts 'Shutting down the BunnyFarm due to control-C request'
  end

  unless BunnyFarm::CONFIG.channel.nil?
    BunnyFarm::CONFIG.channel.work_pool.shutdown
    BunnyFarm::CONFIG.channel.work_pool.kill if BunnyFarm::CONFIG.channel.work_pool.running?
    BunnyFarm::CONFIG.channel.close
    BunnyFarm::CONFIG.connection.close
  end
end # at_exit do


